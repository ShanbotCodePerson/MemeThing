//
//  FriendTableViewCell.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/31/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class FriendTableViewCell: UITableViewCell {

    // MARK: - Set Up UI
    
    func setUpViews(section: Int, username: String, points: Int? = nil) {
        addAllSubviews()
        constrainViews()
        
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
    
    private func addAllSubviews() {
        addSubviews(stackView, usernameLabel, pointsLabel, buttonStackView, acceptButton, denyButton)
    }
    
    private func constrainViews() {
        stackView.anchor(top: contentView.topAnchor, bottom: nil, leading: contentView.leadingAnchor, trailing: nil, width: contentView.frame.width, height: contentView.frame.height)
    }
    
    private func activateButtons() {
        // TODO: - add button functionality
    }
    
    private func pendingFriendRequestView(_ username: String) {
        stackView.addArrangedSubview(usernameLabel)
        stackView.addArrangedSubview(buttonStackView)
        buttonStackView.addArrangedSubview(acceptButton)
        buttonStackView.addArrangedSubview(denyButton)
        
        activateButtons()
        
        usernameLabel.text = "\(username) has sent you a friend request"
        
        contentView.backgroundColor = .systemGreen
    }
    
    private func outgoingFriendRequestView(_ username: String) {
        stackView.addArrangedSubview(usernameLabel)
        
        usernameLabel.text = "Waiting for \(username) to respond to your friend request"
        
        contentView.backgroundColor = .systemRed
    }
    
    private func friendView(_ username: String, points: Int?) {
        stackView.addArrangedSubview(usernameLabel)
        stackView.addArrangedSubview(pointsLabel)
        
        usernameLabel.text = username
        pointsLabel.text = "Points: \(points ?? 0)"
        
        contentView.backgroundColor = .systemGray5
    }
    
    // MARK: - Actions
    
    // TODO: - button functionality
    
    // MARK: - UI Elements
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    private let usernameLabel: MemeThingLabel = MemeThingLabel()
    private let pointsLabel: MemeThingLabel = MemeThingLabel()
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        return stackView
    }()
    private let acceptButton: UIButton = {
        let button = UIButton()
        button.setTitle("Accept", for: .normal)
        button.contentMode = .center
        return button
    }()
    private let denyButton: UIButton = {
        let button = UIButton()
        button.setTitle("Deny", for: .normal)
        button.contentMode = .center
        return button
    }()
}
