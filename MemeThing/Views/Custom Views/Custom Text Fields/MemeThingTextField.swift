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
