//
//  UIImageExt.swift
//  LHF
//
//  Created by KibbeWater on 3/22/24.
//

import UIKit
import CoreImage

extension UIImage {
    func dominantColor() -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        let filter = CIFilter(name: "CIAreaHistogram", parameters: [kCIInputImageKey: inputImage, "inputExtent": extentVector, "inputCount": 10, "inputScale": NSNumber(value: 1)])
        guard let outputImage = filter?.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 40) // 10 bins of RGBA
        let context = CIContext()
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 40, bounds: CGRect(x: 0, y: 0, width: 10, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        var maxVal = CGFloat(0)
        var dominantColor = UIColor.black // Default to black

        for i in stride(from: 0, to: 40, by: 4) {
            let alpha = CGFloat(bitmap[i+3])
            if alpha > maxVal {
                maxVal = alpha
                dominantColor = UIColor(red: CGFloat(bitmap[i]) / 255.0, green: CGFloat(bitmap[i+1]) / 255.0, blue: CGFloat(bitmap[i+2]) / 255.0, alpha: alpha / 255.0)
            }
        }

        return dominantColor
    }
}
