//
//  FriendTableViewCell.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/31/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

protocol FriendTableViewCellButtonDelegate: class {
    func friendRequestResponse(for cell: FriendTableViewCell, accepted: Bool)
}

class FriendTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var buttonStackView: UIStackView!
    
    // MARK: - Properties
    
    weak var delegate: FriendTableViewCellButtonDelegate?
    
    // MARK: - Actions
    
    @IBAction func friendRequestButtonTapped(_ sender: UIButton) {
        delegate?.friendRequestResponse(for: self, accepted: (sender.tag == 1))
    }
    
    // MARK: - Set Up UI

    func setUpViews(section: Int, username: String?, points: Int? = nil) {
        switch section {
        case 0:
            pendingFriendRequestView(username)
        case 1:
            outgoingFriendRequestView(username)
        case 2:
            friendView(username, points: points)
        default:
            return
        }
    }

    private func pendingFriendRequestView(_ username: String?) {
        pointsLabel.isHidden = true
        if let username = username {
            usernameLabel.text = "\(username) has sent you a friend request"
            contentView.backgroundColor = .systemGreen
        } else {
            usernameLabel.text = "You have no new friend requests"
        }
    }

    private func outgoingFriendRequestView(_ username: String?) {
        pointsLabel.isHidden = true
        buttonStackView.isHidden = true
        if let username = username {
            usernameLabel.text = "Waiting for \(username) to respond to your friend request"
            contentView.backgroundColor = .systemRed
        } else {
            usernameLabel.text = "You have no unanswered friend requests"
        }
    }

    private func friendView(_ username: String?, points: Int?) {
        buttonStackView.isHidden = true
        if let username = username {
            usernameLabel.text = username
            pointsLabel.text = "Points: \(points ?? 0)"
        } else {
            usernameLabel.text = "You have not yet added any friends"
        }
    }
}
