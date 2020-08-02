//
//  MemeImageView.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/3/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func roundCornersForAspectFit(radius: CGFloat) {
        print("got here to \(#function)")
        if let image = self.image {
            print("got here to \(#function) and \(image)")
            let boundsScale = self.bounds.size.width / self.bounds.size.height
            let imageScale = image.size.width / image.size.height
            
            var drawingRect : CGRect = self.bounds
            
            if boundsScale > imageScale {
                drawingRect.size.width =  drawingRect.size.height * imageScale
                drawingRect.origin.x = (self.bounds.size.width - drawingRect.size.width) / 2
            } else {
                drawingRect.size.height = drawingRect.size.width / imageScale
                drawingRect.origin.y = (self.bounds.size.height - drawingRect.size.height) / 2
            }
            let path = UIBezierPath(roundedRect: drawingRect, cornerRadius: radius)
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            self.layer.mask = mask
        }
    }
}

class BadgeImage: UIImageView {
    override func awakeFromNib() {
        super.awakeFromNib()
        addCornerRadius(17.5)
    }
}

class ProfileImage: UIImageView {
    override func awakeFromNib() {
        super.awakeFromNib()
        addCornerRadius(self.frame.height / 2)
        addBorder(width: 4)
    }
}
