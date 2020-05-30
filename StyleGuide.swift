//
//  StyleGuide.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/29/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UIView {
    
    func addCornerRadius(_ radius: CGFloat = 8) {
        layer.cornerRadius = radius
        clipsToBounds = true
    }
    
    func addBorder(width: CGFloat = 4, color: UIColor = .darkGray) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
}
