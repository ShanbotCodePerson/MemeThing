//
//  SelfSizingTableView.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/10/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class SelfSizingTableView: UITableView {
    
    var maxHeight: CGFloat = UIScreen.main.bounds.size.height * 0.9
    
    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
        self.layoutIfNeeded()
    }
    
    override var intrinsicContentSize: CGSize {
        let cellHeights = visibleCells.map({ $0.frame.size.height }).reduce(0, +)
        
        let height = min(cellHeights, maxHeight)
        if contentSize.height * 1.4 < maxHeight {
            isScrollEnabled = false
        }
        return CGSize(width: contentSize.width, height: height)
    }
}
