//
//  MemeThingTextField.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/10/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class MemeThingTextField: UITextField {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        addCornerRadius()
        addBorder()
    }
}

// FIXME: - try to get this working
class TwentyCharacterTextField: UITextField {
    
    override func shouldChangeText(in range: UITextRange, replacementText text: String) -> Bool {
        guard let textFieldText = self.text else { return true }
//        let newLength = textFieldText.count + text.count + (range.end - range.start)
//        return newLength <= 20
        return false
    }
}
