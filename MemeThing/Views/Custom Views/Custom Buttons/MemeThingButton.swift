//
//  MemeThingButton.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/29/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UIButton {
    func setUpViews(cornerRadius: CGFloat = 8, borderWidth: CGFloat = 4, borderColor: UIColor = .darkGray, backgroundColor: UIColor = .white, textColor: UIColor = .darkGray, tintColor: UIColor = .darkGray, fontSize: CGFloat = 22, fontName: String = FontNames.mainFont) {
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
        setUpViews(borderColor: .purpleAccent, backgroundColor: .yellowAccent)
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

class SubmitButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(borderWidth: 2, backgroundColor: .greenAccent, textColor: .white)
    }
}

class CloseButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(borderWidth: 2, backgroundColor: .redAccent, textColor: .white)
    }
}

class CircularButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(cornerRadius: self.frame.height / 2, backgroundColor: .systemGray4, tintColor: .darkGray)
    }
}

class AcceptButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(cornerRadius: 0, borderWidth: 0, backgroundColor: .greenAccent, textColor: .white, tintColor: .white)
    }
}

class DenyButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(cornerRadius: 0, borderWidth: 0, backgroundColor: .redAccent, textColor: .white, tintColor: .white)
    }
}
