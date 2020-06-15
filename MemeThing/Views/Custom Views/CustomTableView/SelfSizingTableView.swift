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
        let height = min(contentSize.height * 1.2, maxHeight) // FIXME: - need a proper height for this based on number of cells
        if contentSize.height * 1.2 < maxHeight {
            isScrollEnabled = false
        }
        return CGSize(width: contentSize.width, height: height)
    }
}
