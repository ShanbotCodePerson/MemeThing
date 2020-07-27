//
//  MemeThingTableCellView.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/9/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class MemeThingTableCellView: UIView {
    override func awakeFromNib() {
        super.awakeFromNib()
        addCornerRadius(8)
        self.backgroundColor = UIColor.cellBackground.withAlphaComponent(0.6)
    }
}

class MemeThingViewSubtle: UIView {
    override func awakeFromNib() {
        super.awakeFromNib()
        addCornerRadius(8)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.1)
    }
}
