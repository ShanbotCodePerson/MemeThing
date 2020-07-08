//
//  UIImageExtension.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/30/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import UIKit.UIImage

extension UIImage {
    
    func compressTo(_ expectedSizeInMb: Double) -> Data? {
        let sizeInBytes = Int(expectedSizeInMb * 1024 * 1024)
        var needCompress: Bool = true
        var imageData: Data?
        var compressingValue: CGFloat = 1.0
        while (needCompress && compressingValue > 0.0) {
            if let data:Data = self.jpegData(compressionQuality: compressingValue) {
                if data.count < sizeInBytes {
                    needCompress = false
                    imageData = data
                } else {
                    compressingValue -= 0.1
                }
            }
        }
        
        if let data = imageData, data.count < sizeInBytes { return data }
        return nil
    }
}
