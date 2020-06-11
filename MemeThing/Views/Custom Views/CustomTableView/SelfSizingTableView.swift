//
//  SelfSizingTableView.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/10/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class SelfSizingTableView: UITableView {
    
    var maxHeight: CGFloat = UIScreen.main.bounds.size.height
    
    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
        self.layoutIfNeeded()
    }
    
    override var intrinsicContentSize: CGSize {
        let height = min(contentSize.height, maxHeight)
        return CGSize(width: contentSize.width, height: height)
    }
}
