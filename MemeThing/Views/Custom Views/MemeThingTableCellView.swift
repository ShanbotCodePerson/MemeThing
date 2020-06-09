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
        self.backgroundColor = UIColor.purpleAccent.withAlphaComponent(0.6)
    }
}
