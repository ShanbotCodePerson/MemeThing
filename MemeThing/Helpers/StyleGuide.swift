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
    
    func addBorder(width: CGFloat = 2, color: UIColor = .darkGray) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
    
    //Beth added:
    func addStrokeAndShadow(label: UILabel, string: String, textColor: UIColor, shadowColor: UIColor, strokeColor: UIColor, fontSize: CGFloat) {
        let shadow = NSShadow()
        shadow.shadowColor = shadowColor
        shadow.shadowBlurRadius = 5
        let str = NSAttributedString(string: string, attributes: [
            NSAttributedString.Key.foregroundColor : textColor,
            NSAttributedString.Key.strokeColor : strokeColor,
            NSAttributedString.Key.strokeWidth : -1,
            NSAttributedString.Key.font : UIFont(name: FontNames.titleFont, size: fontSize),
            NSAttributedString.Key.shadow :shadow
            ])
        label.attributedText = str
    }
}

extension UIColor {
    static let background = UIColor(named: "background")!
    static let border = UIColor(named: "border")!
    static let navBar = UIColor(named: "navBar")!
    static let navBarText = UIColor(named: "navBarText")!
    static let loginBox = UIColor(named: "loginBox")!
    static let loginBoxFaded = UIColor(named: "loginBoxFaded")!
    static let loadingIcon = UIColor(named: "loadingIcon")!
    static let loadingIconBackground = UIColor(named: "loadingIconBackground")!
    static let purpleAccent = UIColor(named: "purpleAccent")!
    static let pinkAccent = UIColor(named: "pinkAccent")!
    static let greenAccent = UIColor(named: "greenAccent")!
    static let redAccent = UIColor(named: "redAccent")!
    static let neutralAccent = UIColor(named: "neutralAccent")!
    static let buttonText = UIColor(named: "buttonText")!
    static let lightBlueAccent = UIColor(named: "lightBlueAccent")!
    static let mainText = UIColor(named: "mainText")!
    static let textBackground = UIColor(named: "textBackground")!
    static let cellBackground = UIColor(named: "cellBackground")!
}

struct FontNames {
    static let otherPossibleFont = "Futura-Bold"
    static let mainFont = "MarkerFelt-Thin"
    static let titleFont = "MarkerFelt-Wide"
}
