//
//  MemeThingButton.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/29/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UIButton {
    func setUpViews(cornerRadius: CGFloat = 20, borderWidth: CGFloat = 4, borderColor: UIColor = .border, backgroundColor: UIColor = .white, textColor: UIColor = .buttonText, tintColor: UIColor = .darkGray, fontSize: CGFloat = 22, fontName: String = FontNames.mainFont) {
        addCornerRadius(cornerRadius)
        addBorder(width: borderWidth, color: borderColor)
        self.backgroundColor = backgroundColor
        setTitleColor(textColor, for: .normal)
        self.tintColor = tintColor
        titleLabel?.font = UIFont(name: fontName, size: fontSize)
    }
    
    func deactivate() {
        isUserInteractionEnabled = false
        isEnabled = false
        backgroundColor = backgroundColor?.withAlphaComponent(0.5)
    }
    
    func activate() {
        isUserInteractionEnabled = true
        isEnabled = true
        backgroundColor = backgroundColor?.withAlphaComponent(1)
    }
}

class MemeThingButton: UIButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(backgroundColor: .orange, fontSize: 35)
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
        setUpViews(borderWidth: 2, backgroundColor: .greenAccent)
        titleLabel?.font = UIFont(name: FontNames.mainFont, size: 35)
    }
}

class CloseButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(borderWidth: 2, backgroundColor: .orangeAccent)
    }
}

class QuitButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(borderWidth: 2, backgroundColor: .redAccent)
    }
}

class CircularButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        setUpViews(cornerRadius: self.frame.height / 2, backgroundColor: .lightGray, tintColor: .darkGray)
    }
}

class AcceptButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(cornerRadius: 8, borderWidth: 0, backgroundColor: UIColor.greenAccent.withAlphaComponent(0.8))
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
    }
}

class DenyButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(cornerRadius: 0, borderWidth: 0, backgroundColor: UIColor.redAccent.withAlphaComponent(0.8))
    }
}

class EditButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpViews(cornerRadius: 16, borderWidth: 0, backgroundColor: UIColor.white.withAlphaComponent(0.6), textColor: .darkGray, fontSize: 18)
    }
    
    override var intrinsicContentSize: CGSize { return addInsets(to: super.intrinsicContentSize) }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return addInsets(to: super.sizeThatFits(size))
    }
    
    private func addInsets(to size: CGSize) -> CGSize {
        let width = size.width + 12
        let height = size.height + 2
        return CGSize(width: width, height: height)
    }
}
