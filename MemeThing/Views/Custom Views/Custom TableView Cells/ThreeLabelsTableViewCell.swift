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
    
    @IBOutlet weak var photoContainerView: UIView!
    @IBOutlet weak var profilePhotoImageView: ProfileImage!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selectionStyle = .none
        
        // Change the colors when the cell is selected
        if selected {
            containerView.backgroundColor = UIColor.greenAccent.withAlphaComponent(1)
            firstLabel.textColor = UIColor.background.withAlphaComponent(0.6)
            secondLabel.textColor = UIColor.background.withAlphaComponent(0.6)
        }
        else {
            containerView.backgroundColor = UIColor.cellBackground.withAlphaComponent(0.6)
            firstLabel.textColor = .mainText
            secondLabel.textColor = .mainText
        }
    }
    
    // MARK: - Set Up UI
    
    func setUpUI(firstText: String, secondText: String? = nil, thirdText: String? = nil, photo: UIImage? = nil) {
        containerView.addCornerRadius(8)
        containerView.backgroundColor = UIColor.purpleAccent.withAlphaComponent(0.6)
 
        // Reset all values to default (in case cell is being reused)
        firstLabel.textAlignment = .left
        secondLabel.textAlignment = .left
        secondLabel.isHidden = false
        thirdLabel.isHidden = false
        photoContainerView.isHidden = true
        
        // Fill in the text fields as applicable
        firstLabel.text = firstText
        if let secondText = secondText { secondLabel.text = secondText }
        else {
            firstLabel.textAlignment = .center
            secondLabel.isHidden = true
        }
        if let thirdText = thirdText { thirdLabel.text = thirdText }
        else {
            secondLabel.textAlignment = .right
            thirdLabel.isHidden = true
        }
        if let photo = photo {
            photoContainerView.isHidden = false
            profilePhotoImageView.image = photo
            profilePhotoImageView.addBorder(width: 2)
        }
    }
}
