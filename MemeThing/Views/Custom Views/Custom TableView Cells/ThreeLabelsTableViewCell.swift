//
//  ThreeLabelsTableViewCell.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/10/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class ThreeLabelsTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var containerView: UIView!

//    override func awakeFromNib() {
//        super.awakeFromNib()
//        // Initialization code
//    }
//
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//    }

    
    // MARK: - Set Up UI
    
    func setUpUI(_ firstText: String, _ secondText: String, _ thirdText: String?) {
        containerView.addCornerRadius(8)
        containerView.backgroundColor = UIColor.purpleAccent.withAlphaComponent(0.6)
        
        firstLabel.text = firstText
        secondLabel.text = secondText
        if let thirdText = thirdText { thirdLabel.text = thirdText }
        else {
            secondLabel.textAlignment = .right
            thirdLabel.isHidden = true
        }
    }
    
    func setUpUI(_ firstText: String) {
        containerView.addCornerRadius(8)
        containerView.backgroundColor = UIColor.purpleAccent.withAlphaComponent(0.6)
        
        firstLabel.text = firstText
        firstLabel.textAlignment = .center
        secondLabel.isHidden = true
        thirdLabel.isHidden = true
    }
}
