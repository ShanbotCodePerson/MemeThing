//
//  FriendTableViewCell.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/31/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

// MARK: - Button Protocol

protocol FriendTableViewCellButtonDelegate: class {
    func respondToFriendRequest(from cell: FriendTableViewCell, accept: Bool)
}

class FriendTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    
    
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
            setUpPendingFriendRequestView(for: username)
        case .outgoingFriendRequests:
            guard let username = username else { return }
            setUpOutgoingFriendRequestView(for: username)
        case .friends:
            setUpFriendView(for: username, points: points)
        }
    }
    
    private func setUpPendingFriendRequestView(for username: String) {
        pointsLabel.isHidden = true
        buttonStackView.isHidden = false
        usernameLabel.text = "\(username) has sent you a friend request"
        contentView.backgroundColor = .systemGreen
    }
    
    private func setUpOutgoingFriendRequestView(for username: String) {
        pointsLabel.isHidden = true
        buttonStackView.isHidden = true
        usernameLabel.text = "Waiting for \(username) to respond to your friend request"
        contentView.backgroundColor = .systemRed
    }
    
    private func setUpFriendView(for username: String?, points: Int?) {
        buttonStackView.isHidden = true
        contentView.backgroundColor = .clear
        
        if let username = username {
            usernameLabel.text = username
            pointsLabel.text = "Points: \(points ?? 0)"
            pointsLabel.textAlignment = .right
            rightConstraint.constant = 6
            pointsLabel.isHidden = false
        } else {
            usernameLabel.text = "You have not added any friends yet"
            usernameLabel.textAlignment = .center
            pointsLabel.isHidden = true
        }
    }
}
