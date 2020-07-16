//
//  MemeImageView.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/3/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class MemeImageView: UIImageView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addCornerRadius()
        addBorder()
    }
}
