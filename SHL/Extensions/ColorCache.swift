//
//  ColorCache.swift
//  SHL
//
//  Created by Linus Rönnbäck Larsson on 20/9/24.
//

import UIKit

public class ColorCache {
    static let shared = ColorCache()
    
    private let memoryCache = NSCache<NSString, UIColor>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ColorCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func cacheColor(_ color: UIColor, forKey key: String) {
        // Cache in memory
        memoryCache.setObject(color, forKey: key as NSString)
        
        // Cache on disk
        if #available(iOS 11.0, *) {
            let colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            let fileURL = cacheDirectory.appendingPathComponent(key)
            try? colorData?.write(to: fileURL)
        } else {
            // Fallback for earlier iOS versions
            NSKeyedArchiver.archiveRootObject(color, toFile: cacheDirectory.appendingPathComponent(key).path)
        }
    }
    
    func getColor(forKey key: String) -> UIColor? {
        // Check memory cache first
        if let color = memoryCache.object(forKey: key as NSString) {
            return color
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key)
        if let colorData = try? Data(contentsOf: fileURL) {
            if #available(iOS 12.0, *) {
                if let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                    // Cache the color in memory for faster future access
                    memoryCache.setObject(color, forKey: key as NSString)
                    return color
                }
            } else {
                // Fallback for earlier iOS versions
                if let color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? UIColor {
                    // Cache the color in memory for faster future access
                    memoryCache.setObject(color, forKey: key as NSString)
                    return color
                }
            }
        }
        
        return nil
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
