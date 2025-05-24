//
//  UIImage+Extensions.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import UIKit

extension UIImage {
    // Compare two UIImages for equality based on their data representation
    func hasSameImageData(as other: UIImage?) -> Bool {
        guard let other = other else { return false }
        
        // Quick size comparison first (optimization)
        if self.size != other.size { return false }
        
        // Compare data representation
        guard let selfData = self.pngData(),
              let otherData = other.pngData() else {
            return false
        }
        
        return selfData == otherData
    }
}