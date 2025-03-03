//
//  DominantColorExtractor.swift
//  Efficient dominant color extraction using Metal for GPU acceleration
//

import SwiftUI
import Metal
import MetalKit
import Combine
import CoreImage.CIFilterBuiltins

/// A utility class for extracting dominant colors from images using GPU acceleration
public class DominantColorExtractor {
    // MARK: - Shared Instance
    
    /// Shared instance for easy access across the app
    public static let shared: DominantColorExtractor = {
        do {
            return try DominantColorExtractor()
        } catch {
            fatalError("Failed to initialize shared DominantColorExtractor: \(error)")
        }
    }()
    
    // MARK: - Static API
    
    /// Get the dominant color of an asset by name
    /// - Parameter asset: The name of the asset in the asset catalog
    /// - Returns: The dominant color or nil if extraction fails
    public static func getDominantColor(asset: String) -> Color? {
        guard let image = UIImage(named: asset) else {
            print("Could not load image asset named: \(asset)")
            return nil
        }
        
        do {
            return try shared.extractDominantColor(from: image)
        } catch {
            print("Failed to extract dominant color from \(asset): \(error)")
            return nil
        }
    }
    
    /// Get the dominant color of an asset by name, with a fallback color
    /// - Parameters:
    ///   - asset: The name of the asset in the asset catalog
    ///   - fallback: The fallback color to use if extraction fails
    /// - Returns: The dominant color or the fallback color if extraction fails
    public static func getDominantColor(asset: String, fallback: Color) -> Color {
        return getDominantColor(asset: asset) ?? fallback
    }
    
    /// Get the dominant color from a UIImage
    /// - Parameter image: The UIImage to analyze
    /// - Returns: The dominant color or nil if extraction fails
    public static func getDominantColor(image: UIImage) -> Color? {
        do {
            return try shared.extractDominantColor(from: image)
        } catch {
            print("Failed to extract dominant color: \(error)")
            return nil
        }
    }
    
    /// Batch process multiple assets and get their dominant colors
    /// - Parameter assets: Array of asset names
    /// - Returns: Dictionary mapping asset names to their dominant colors
    public static func getDominantColors(assets: [String]) -> [String: Color] {
        let images = assets.compactMap { (asset: String) -> (String, UIImage)? in
            guard let image = UIImage(named: asset) else { return nil }
            return (asset, image)
        }
        
        let assetImages = images.map { $0.1 }
        let assetNames = images.map { $0.0 }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        var results: [UIImage: Color] = [:]
        
        shared.extractDominantColors(from: assetImages) { imageResults in
            results = imageResults
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        
        // Map back to asset names
        var assetColors: [String: Color] = [:]
        for (index, image) in assetImages.enumerated() {
            if let color = results[image] {
                assetColors[assetNames[index]] = color
            }
        }
        
        return assetColors
    }
    
    // MARK: - Cache
    
    /// A cache for storing dominant colors by asset name
    private static var colorCache: [String: Color] = [:]
    
    /// Get the dominant color from the cache, or compute and cache it if not present
    /// - Parameter asset: The name of the asset in the asset catalog
    /// - Returns: The dominant color or nil if extraction fails
    public static func getCachedDominantColor(asset: String) -> Color? {
        // Check cache first
        if let cachedColor = colorCache[asset] {
            return cachedColor
        }
        
        // Compute and cache the color
        if let color = getDominantColor(asset: asset) {
            colorCache[asset] = color
            return color
        }
        
        return nil
    }
    
    /// Clear the color cache
    public static func clearCache() {
        colorCache.removeAll()
    }
    
    // MARK: - Private Properties
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary
    private let pipelineState: MTLComputePipelineState
    private let context = CIContext()
    
    // MARK: - Initialization
    
    /// Creates a new instance of the DominantColorExtractor
    /// - Throws: DominantColorError if Metal setup fails
    public init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw DominantColorError.metalDeviceNotFound
        }
        
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else {
            throw DominantColorError.commandQueueCreationFailed
        }
        self.commandQueue = commandQueue
        
        // Create Metal library from default shaders
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        kernel void dominantColorKernel(texture2d<float, access::read> inTexture [[texture(0)]],
                                        device atomic_uint* histogram [[buffer(0)]],
                                        uint2 gid [[thread_position_in_grid]]) {
            if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) {
                return;
            }
            
            float4 color = inTexture.read(gid);
            
            // Convert to RGB888 space
            uint r = uint(color.r * 255.0);
            uint g = uint(color.g * 255.0);
            uint b = uint(color.b * 255.0);
            
            // Use fewer bits per channel for a manageable histogram (4 bits per channel = 4096 colors)
            r = r >> 4;
            g = g >> 4;
            b = b >> 4;
            
            // Calculate index in the histogram (4 bits per channel = 16 values per channel)
            uint index = (r << 8) | (g << 4) | b;
            
            // Update histogram atomically
            atomic_fetch_add_explicit(&histogram[index], 1, memory_order_relaxed);
        }
        """
        
        let options = MTLCompileOptions()
        
        do {
            library = try device.makeLibrary(source: shaderSource, options: options)
        } catch {
            throw DominantColorError.libraryCreationFailed(error)
        }
        
        guard let kernelFunction = library.makeFunction(name: "dominantColorKernel") else {
            throw DominantColorError.kernelFunctionNotFound
        }
        
        do {
            pipelineState = try device.makeComputePipelineState(function: kernelFunction)
        } catch {
            throw DominantColorError.pipelineCreationFailed(error)
        }
    }
    
    // MARK: - Public Methods
    
    /// Extracts dominant colors from multiple images concurrently using GPU acceleration
    /// - Parameters:
    ///   - images: Array of UIImages to process
    ///   - completion: Closure called with the results as a dictionary mapping images to colors
    /// - Returns: A cancellable task that can be used to cancel the operation
    @discardableResult
    public func extractDominantColors(from images: [UIImage],
                                     completion: @escaping ([UIImage: Color]) -> Void) -> AnyCancellable {
        return Future<[UIImage: Color], Never> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                var results = [UIImage: Color]()
                let group = DispatchGroup()
                let queue = DispatchQueue(label: "com.dominantcolor.processing", attributes: .concurrent)
                
                for image in images {
                    group.enter()
                    queue.async {
                        do {
                            let color = try self.extractDominantColor(from: image)
                            DispatchQueue.main.async {
                                results[image] = color
                                group.leave()
                            }
                        } catch {
                            print("Error extracting color: \(error)")
                            DispatchQueue.main.async {
                                group.leave()
                            }
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    promise(.success(results))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { result in
            completion(result)
        }
    }
    
    /// Extracts dominant color from a single image using GPU acceleration
    /// - Parameter image: UIImage to process
    /// - Returns: The dominant Color
    /// - Throws: DominantColorError if processing fails
    public func extractDominantColor(from image: UIImage) throws -> Color {
        guard let cgImage = image.cgImage else {
            throw DominantColorError.invalidImage
        }
        
        // Create a texture from the image
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: cgImage.width,
            height: cgImage.height,
            mipmapped: false
        )
        
        textureDescriptor.usage = [.shaderRead]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            throw DominantColorError.textureCreationFailed
        }
        
        // Copy the image data to the texture
        let region = MTLRegionMake2D(0, 0, cgImage.width, cgImage.height)
        let bytesPerRow = 4 * cgImage.width
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw DominantColorError.contextCreationFailed
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        
        if let data = context.data {
            texture.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: bytesPerRow)
        }
        
        // Create histogram buffer (4 bits per channel = 16^3 = 4096 colors)
        let histogramSize = 4096 * MemoryLayout<UInt32>.size
        guard let histogramBuffer = device.makeBuffer(length: histogramSize, options: .storageModeShared) else {
            throw DominantColorError.bufferCreationFailed
        }
        
        // Zero out the histogram buffer
        memset(histogramBuffer.contents(), 0, histogramSize)
        
        // Create command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw DominantColorError.commandBufferCreationFailed
        }
        
        // Create compute command encoder
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw DominantColorError.computeEncoderCreationFailed
        }
        
        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setBuffer(histogramBuffer, offset: 0, index: 0)
        
        // Calculate grid size and thread group size
        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let gridSize = MTLSize(
            width: (cgImage.width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (cgImage.height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(gridSize, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
        
        // Execute the command buffer
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // Find the most frequent color
        let histogramData = histogramBuffer.contents().bindMemory(to: UInt32.self, capacity: 4096)
        var maxCount: UInt32 = 0
        var maxIndex: Int = 0
        
        for i in 0..<4096 {
            if histogramData[i] > maxCount {
                maxCount = histogramData[i]
                maxIndex = i
            }
        }
        
        // Convert index back to RGB
        let r = CGFloat((maxIndex >> 8) & 0xF) / 15.0
        let g = CGFloat((maxIndex >> 4) & 0xF) / 15.0
        let b = CGFloat(maxIndex & 0xF) / 15.0
        
        return Color(red: r, green: g, blue: b)
    }
    
    // MARK: - SwiftUI Extensions
    
    /// Returns a publisher that emits the dominant color for an image
    /// - Parameter image: The image to analyze
    /// - Returns: A publisher that emits a Color or an error
    public func dominantColorPublisher(for image: UIImage) -> AnyPublisher<Color, Error> {
        return Future<Color, Error> { promise in
            do {
                let color = try self.extractDominantColor(from: image)
                promise(.success(color))
            } catch {
                promise(.failure(error))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}

// MARK: - Error Types

/// Errors that can occur during dominant color extraction
public enum DominantColorError: Error {
    case metalDeviceNotFound
    case commandQueueCreationFailed
    case libraryCreationFailed(Error)
    case kernelFunctionNotFound
    case pipelineCreationFailed(Error)
    case invalidImage
    case textureCreationFailed
    case contextCreationFailed
    case bufferCreationFailed
    case commandBufferCreationFailed
    case computeEncoderCreationFailed
}

// MARK: - SwiftUI Extensions

extension View {
    /// Applies a background color based on the dominant color of an image
    /// - Parameters:
    ///   - image: The image to extract color from
    ///   - extractor: The DominantColorExtractor instance
    ///   - opacity: The opacity of the background color
    /// - Returns: A view modified with the dominant color background
    public func backgroundDominantColor(from image: UIImage?,
                                       using extractor: DominantColorExtractor = DominantColorExtractor.shared,
                                       opacity: Double = 1.0) -> some View {
        modifier(DominantColorBackgroundModifier(image: image, extractor: extractor, opacity: opacity))
    }
    
    /// Applies a background color based on the dominant color of an asset
    /// - Parameters:
    ///   - asset: The name of the asset to extract color from
    ///   - opacity: The opacity of the background color
    /// - Returns: A view modified with the dominant color background
    public func backgroundDominantColor(fromAsset asset: String,
                                       opacity: Double = 1.0) -> some View {
        let color = DominantColorExtractor.getCachedDominantColor(asset: asset) ?? .clear
        return background(color.opacity(opacity))
    }
}

/// A ViewModifier that applies the dominant color of an image as a background
public struct DominantColorBackgroundModifier: ViewModifier {
    private let image: UIImage?
    private let extractor: DominantColorExtractor
    private let opacity: Double
    @State private var dominantColor: Color = .clear
    @State private var cancellable: AnyCancellable?
    
    public init(image: UIImage?, extractor: DominantColorExtractor, opacity: Double) {
        self.image = image
        self.extractor = extractor
        self.opacity = opacity
    }
    
    public func body(content: Content) -> some View {
        content
            .background(dominantColor.opacity(opacity))
            .onAppear {
                loadColor()
            }
            .onChange(of: image) { _, _ in
                loadColor()
            }
    }
    
    private func loadColor() {
        cancellable?.cancel()
        
        guard let image = image else {
            dominantColor = .clear
            return
        }
        
        cancellable = extractor.dominantColorPublisher(for: image)
            .replaceError(with: .clear)
            .sink { color in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.dominantColor = color
                }
            }
    }
}

// MARK: - Convenience extensions

extension Image {
    /// Creates a view that displays a dominant color as background based on this image
    /// - Parameters:
    ///   - extractor: The DominantColorExtractor instance
    ///   - opacity: The opacity of the background color
    /// - Returns: A view with the image and its dominant color as background
    public func withDominantColorBackground(using extractor: DominantColorExtractor = DominantColorExtractor.shared,
                                           opacity: Double = 0.3) -> some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                    .backgroundDominantColor(from: self.asUIImage(size: geometry.size),
                                           using: extractor,
                                           opacity: opacity)
                self
                    .resizable()
                    .scaledToFit()
            }
        }
    }
    
    /// Converts this SwiftUI Image to a UIImage
    /// - Parameter size: The desired size of the UIImage
    /// - Returns: A UIImage representation of this image
    private func asUIImage(size: CGSize) -> UIImage? {
        let controller = UIHostingController(rootView:
            self
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        )
        controller.view.frame = CGRect(origin: .zero, size: size)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

extension UIImage {
    /// Returns the dominant color of this image
    /// - Parameter extractor: The DominantColorExtractor instance
    /// - Returns: The dominant Color or nil if extraction fails
    public func dominantColor(using extractor: DominantColorExtractor = DominantColorExtractor.shared) -> Color? {
        try? extractor.extractDominantColor(from: self)
    }
}
