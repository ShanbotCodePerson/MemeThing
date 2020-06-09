//
//  ThreeLabelsTableViewCell.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/8/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class ThreeLabelsTableViewCell: UITableViewCell {

    // MARK: - Outlets
    
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!

    // MARK: - Set Up UI
    
    func setUpUI(_ firstText: String, _ secondText: String, _ thirdText: String?) {
        print("got here to \(#function) in ThreeLabelsTableViewCell and firstLabel is \(firstLabel)")
        if firstLabel == nil { return }
        firstLabel.text = firstText
        secondLabel.text = secondText
        if let thirdText = thirdText { thirdLabel.text = thirdText }
        else { thirdLabel.isHidden = true }
    }
}
