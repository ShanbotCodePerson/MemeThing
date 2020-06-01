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
    
    // MARK: - Properties
    
    weak var delegate: FriendTableViewCellButtonDelegate?
    
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
        stackView.anchor(top: contentView.topAnchor, bottom: contentView.bottomAnchor, leading: contentView.leadingAnchor, trailing: contentView.trailingAnchor)
        
        usernameLabel.numberOfLines = 0
        pointsLabel.numberOfLines = 0
    }
    
    private func activateButtons() {
        acceptButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        denyButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
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
    
    @objc func buttonTapped(_ sender: UIButton) {
        delegate?.friendRequestResponse(for: self, accepted: (sender.tag == 1))
    }
    
    // MARK: - UI Elements
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    private let usernameLabel: UILabel = MemeThingLabel()
    private let pointsLabel: UILabel = MemeThingLabel()
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }()
    private let acceptButton: UIButton = {
        let button = UIButton()
        button.tag = 1
        button.setTitle("Accept", for: .normal)
        button.contentMode = .center
        return button
    }()
    private let denyButton: UIButton = {
        let button = UIButton()
        button.tag = 2
        button.setTitle("Deny", for: .normal)
        button.contentMode = .center
        return button
    }()
}
