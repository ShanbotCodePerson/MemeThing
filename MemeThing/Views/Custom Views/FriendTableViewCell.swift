//
//  FriendTableViewCell.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/31/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

protocol FriendTableViewCellButtonDelegate: class {
    func respondToFriendRequest(from cell: FriendTableViewCell, accept: Bool)
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
        delegate?.respondToFriendRequest(from: self, accept: (sender.tag == 1))
    }
    
    // MARK: - Set Up UI
    
    func setUpViews(section: FriendsListTableViewController.SectionNames, username: String?, points: Int? = nil) {
        switch section {
        case .pendingFriendRequests:
            guard let username = username else { return }
            pendingFriendRequestView(username)
        case .outgoingFriendRequests:
            guard let username = username else { return }
            outgoingFriendRequestView(username)
        case .friends:
            friendView(username, points: points)
        }
    }
    
    private func pendingFriendRequestView(_ username: String) {
        pointsLabel.isHidden = true
        usernameLabel.text = "\(username) has sent you a friend request"
        contentView.backgroundColor = .systemGreen
    }
    
    private func outgoingFriendRequestView(_ username: String) {
        pointsLabel.isHidden = true
        buttonStackView.isHidden = true
        usernameLabel.text = "Waiting for \(username) to respond to your friend request"
        contentView.backgroundColor = .systemRed
    }
    
    private func friendView(_ username: String?, points: Int?) {
        buttonStackView.isHidden = true
        if let username = username {
            usernameLabel.text = username
            pointsLabel.text = "Points: \(points ?? 0)"
        } else {
            usernameLabel.text = "You have not yet added any friends"
            pointsLabel.isHidden = true
        }
    }
}
