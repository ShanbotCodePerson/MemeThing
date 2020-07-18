//
//  GameTableViewCell.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/4/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

// MARK: - Button Protocol

protocol GameTableViewCellDelegate: class {
    func respondToGameInvitation(for cell: GameTableViewCell, accept: Bool)
}

class GameTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var mainTextLabel: UILabel!
    @IBOutlet weak var secondaryTextLabel: UILabel!
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var backgroundContainerView: UIView!
    
    // MARK: - Properties
    
    weak var delegate: GameTableViewCellDelegate?
    
    // MARK: - Actions
    
    @IBAction func invitationResponseButtonTapped(_ sender: UIButton) {
        // Show the loading icon over the cell
        self.contentView.startLoadingIcon(color: .white)
        
        // Pass the functionality off to the delegate
        delegate?.respondToGameInvitation(for: self, accept: (sender.tag == 1))
    }
    
    // MARK: - Set Up UI
    
    func setUpViews(in section: GamesListViewController.SectionName, with game: Game?) {
        selectionStyle = .none
        
        switch section {
        case .pendingInvitations:
            guard let game = game else { return }
            setUpPendingInvitationView(for: game)
        case .waitingForResponses:
            guard let game = game else { return }
            setUpWaitingForResponseView(for: game)
        case .games:
            setUpActiveGameView(for: game)
        case .finishedGames:
            guard let game = game else { return }
            setUpFinishedGameView(for: game)
        }
    }
    
    private func setUpPendingInvitationView(for game: Game) {
        secondaryTextLabel.isHidden = true
        buttonStackView.isHidden = false
        mainTextLabel.text = "\(game.playersNames[0]) has invited you to a game with \(game.listOfPlayerNames)"
        contentView.backgroundColor = .orange
    }
    
    private func setUpWaitingForResponseView(for game: Game) {
        secondaryTextLabel.isHidden = true
        buttonStackView.isHidden = true
        contentView.backgroundColor = .systemRed
        if let currentUser = UserController.shared.currentUser,
            game.leadPlayerID == currentUser.recordID {
            mainTextLabel.text = "You have sent a game invitation to \(game.listOfPlayerNames)"
        } else {
             mainTextLabel.text = "You have been invited to a game with \(game.listOfPlayerNames)"
        }
    }
    
    private func setUpActiveGameView(for game: Any?) {
        buttonStackView.isHidden = true
        contentView.backgroundColor = .clear
        if let game = game as? Game {
            mainTextLabel.text = "You are playing a game with \(game.listOfPlayerNames)"
            secondaryTextLabel.text = game.gameStatusDescription
            secondaryTextLabel.isHidden = false
        } else {
            secondaryTextLabel.isHidden = true
            mainTextLabel.text = "You are not currently playing any games"
            mainTextLabel.textAlignment = .center
        }
    }
    
    private func setUpFinishedGameView(for game: Game) {
        buttonStackView.isHidden = true
        contentView.backgroundColor = .lightGray
        mainTextLabel.text = "You played a game with \(game.listOfPlayerNames)"
        secondaryTextLabel.text = game.gameStatusDescription
    }
}
