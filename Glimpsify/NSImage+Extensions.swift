//
//  NSImage+Extensions.swift
//  Glimpsify
//
//  Created by Rudrank Riyam on 5/23/25.
//

import AppKit
import SwiftUI

// MARK: - NSImage Extensions
extension NSImage {
    func base64String() -> String {
        guard let tiffData = self.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return ""
        }

        // Resize if too large
        let maxSize: CGFloat = 1_024
        let size = self.size
        let scale = min(maxSize / size.width, maxSize / size.height, 1.0)

        if scale < 1.0 {
            let newSize = NSSize(width: size.width * scale, height: size.height * scale)
            let resizedImage = NSImage(size: newSize)
            resizedImage.lockFocus()
            self.draw(in: NSRect(origin: .zero, size: newSize))
            resizedImage.unlockFocus()

            if let resizedTiff = resizedImage.tiffRepresentation,
               let resizedBitmap = NSBitmapImageRep(data: resizedTiff),
               let jpegData = resizedBitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) {
                return jpegData.base64EncodedString()
            }
        }

        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            return ""
        }

        return jpegData.base64EncodedString()
    }
    
    // Compare two NSImages for equality based on their data representation
    func isEqual(_ other: NSImage?) -> Bool {
        guard let other = other else { return false }
        
        // Quick size comparison first (optimization)
        if self.size != other.size { return false }
        
        // Compare data representation
        guard let selfData = self.tiffRepresentation,
              let otherData = other.tiffRepresentation else {
            return false
        }
        
        return selfData == otherData
    }
}
