//
//  MemeThingLabel.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/29/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UILabel {
    
    func setUpViews(cornerRadius: CGFloat = 8, borderWidth: CGFloat = 0, borderColor: UIColor = .darkGray, backgroundColor: UIColor = .white, opacity: CGFloat = 0.6, textColor: UIColor = .darkGray, fontSize: CGFloat = 20, fontName: String = "Marker-Felt-Thin") {
        addCornerRadius(cornerRadius)
        addBorder(width: borderWidth, color: borderColor)
        self.backgroundColor = backgroundColor.withAlphaComponent(opacity)
        self.textColor = textColor
        font = UIFont(name: fontName, size: fontSize)
    }
}

class MemeThingLabel: UILabel {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews()
    }
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5)
        super.drawText(in: rect.inset(by: insets))
    }
}
