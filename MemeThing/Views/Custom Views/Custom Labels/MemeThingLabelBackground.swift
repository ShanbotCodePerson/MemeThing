//
//  MemeThingLabel.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/29/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UILabel {
    
    func setUpViews(cornerRadius: CGFloat = 8, borderWidth: CGFloat = 0, borderColor: UIColor = .darkGray, backgroundColor: UIColor = .purpleAccent, opacity: CGFloat = 0.6, textColor: UIColor = .mainText, fontSize: CGFloat = 22, fontName: String = FontNames.mainFont) {
        addCornerRadius(cornerRadius)
        addBorder(width: borderWidth, color: borderColor)
        self.backgroundColor = backgroundColor.withAlphaComponent(opacity)
        self.textColor = textColor
        font = UIFont(name: fontName, size: fontSize)
    }
}

class MemeThingLabelBackground: UILabel {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews()
    }
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize { return addInsets(to: super.intrinsicContentSize) }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return addInsets(to: super.sizeThatFits(size))
    }
    
    private func addInsets(to size: CGSize) -> CGSize {
        let width = size.width + 12
        let height = size.height + 6
        return CGSize(width: width, height: height)
    }
}

class MemeThingLabelNoBackground: UILabel {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.textColor = .mainText
        font = UIFont(name: FontNames.mainFont, size: 22)
    }
}

class MemeThingLabelNoBackground: UILabel {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.textColor = .mainText
        font = UIFont(name: FontNames.mainFont, size: 22)
    }
}
