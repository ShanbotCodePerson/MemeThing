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

extension UIColor {
    static let background = UIColor(named: "background")!
    static let navBar = UIColor(named: "navBar")!
    static let purpleAccent = UIColor(named: "purpleAccent")!
    static let greenAccent = UIColor(named: "greenAccent")!
    static let redAccent = UIColor(named: "redAccent")!
    static let yellowAccent = UIColor(named: "yellowAccent")!
    static let mainText = UIColor(named: "mainText")!
    static let accentText = UIColor(named: "accentText")!
    static let textBackground = UIColor(named: "textBackground")!
}

struct FontNames {
    static let otherPossibleFont = "Futura-Bold"
    static let mainFont = "MarkerFelt-Thin"
}
