//
//  MemeThingButton.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/29/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UIButton {
    func setUpViews(cornerRadius: CGFloat = 8, borderWidth: CGFloat = 4, borderColor: UIColor = .darkGray, backgroundColor: UIColor = .white, textColor: UIColor = .darkGray, tintColor: UIColor = .darkGray, fontSize: CGFloat = 20, fontName: String = "Marker-Felt-Thin") {
        addCornerRadius(cornerRadius)
        addBorder(width: borderWidth, color: borderColor)
        self.backgroundColor = backgroundColor
        setTitleColor(textColor, for: .normal)
        self.tintColor = tintColor
        titleLabel?.font = UIFont(name: fontName, size: fontSize)
    }
}

class MemeThingButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews()
    }
}

class SubmitButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(borderWidth: 2, backgroundColor: .systemGreen, textColor: .white)
    }
}

class CircularButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(cornerRadius: self.frame.height / 2, backgroundColor: .systemGray4, tintColor: .darkGray)
    }
}
