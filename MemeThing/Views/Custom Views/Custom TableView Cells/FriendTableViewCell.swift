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
    
    @IBOutlet weak var nameLabel: UILabel!
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
    
    func setUpViews(section: FriendsListTableViewController.SectionNames, name: String?, points: Int? = nil) {
        switch section {
        case .pendingFriendRequests:
            guard let name = name else { return }
            setUpPendingFriendRequestView(for: name)
        case .outgoingFriendRequests:
            guard let name = name else { return }
            setUpOutgoingFriendRequestView(for: name)
        case .friends:
            setUpFriendView(for: name, points: points)
        }
    }
    
    private func setUpPendingFriendRequestView(for name: String) {
        pointsLabel.isHidden = true
        buttonStackView.isHidden = false
        nameLabel.text = "\(name) has sent you a friend request"
        contentView.backgroundColor = .systemGreen
    }
    
    private func setUpOutgoingFriendRequestView(for name: String) {
        pointsLabel.isHidden = true
        buttonStackView.isHidden = true
        nameLabel.text = "Waiting for \(name) to respond to your friend request"
        contentView.backgroundColor = .systemRed
    }
    
    private func setUpFriendView(for name: String?, points: Int?) {
        buttonStackView.isHidden = true
        contentView.backgroundColor = .clear
        
        if let name = name {
            nameLabel.text = name
            pointsLabel.text = "Points: \(points ?? 0)"
            nameLabel.textAlignment = .left
            pointsLabel.textAlignment = .right
            rightConstraint.constant = 6
            pointsLabel.isHidden = false
        } else {
            nameLabel.text = "You have not added any friends yet"
            nameLabel.textAlignment = .center
            pointsLabel.isHidden = true
        }
    }
}
