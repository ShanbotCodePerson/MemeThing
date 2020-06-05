//
//  WaitingViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/28/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class WaitingViewController: UIViewController, HasAGameObject {
    
    // MARK: - Outlets
    
    @IBOutlet weak var waitingLabel: UILabel!
    @IBOutlet weak var waitingForTableView: UITableView!
    
    // MARK: - Properties
    
    var game: Game?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Set up the observers to listen for notifications telling the view to reload its data
        NotificationCenter.default.addObserver(self, selector: #selector(refreshPage(_:)), name: playerRespondedToGameInvite, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshPage(_:)), name: playerSentCaption, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(gameStarting(_:)), name: newRound, object: nil)
        
        // Set up the observers to listen for notifications telling the view to transition to a new page
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: drawingSent, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: allPlayersSentCaptions, object: nil)
    }
    
    // MARK: - Respond to Notifications
    
    @objc func refreshPage(_ sender: NSNotification) {
        print(sender.name)
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID.recordName else { return }
        
        // Refresh the page based on the type of update
        DispatchQueue.main.async {
            if sender.name == playerRespondedToGameInvite {
                self.waitingForTableView.reloadData()
            }
            else if sender.name == playerSentCaption {
                self.waitingForTableView.reloadData()
            }
            // TODO: - refactor to a single line, or even a single notification?
        }
    }
    
    @objc func transitionToNewPage(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID.recordName else { return }
        
        // Transition to the relevant view based on the type of update
        DispatchQueue.main.async {
            if sender.name == drawingSent {
                self.transitionToStoryboard(named: StoryboardNames.captionView, with: game)
            }
            else if sender.name == allPlayersSentCaptions {
                self.transitionToStoryboard(named: StoryboardNames.resultsView, with: game)
            }
        }
    }
    
    @objc func gameStarting(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID.recordName else { return }
        
        // If the current user is the lead player, transition to the drawing view
        DispatchQueue.main.async {
            if game.leadPlayer == UserController.shared.currentUser?.reference {
                self.transitionToStoryboard(named: StoryboardNames.drawingView, with: game)
            } else {
                // Otherwise, refresh the waiting view to reflect that the game is starting
                self.waitingForDrawing(for: game)
            }
        }
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        guard let game = game else { return }
        
        // Set up the view based on the status of the game
        switch game.gameStatus {
        case .waitingForPlayers:
            waitingForInvitationResponses(for: game)
        case .waitingForDrawing:
            waitingForDrawing(for: game)
        case .waitingForCaptions:
            waitingForCaptions(for: game)
        default:
            print("In waiting view and game status is \(game.gameStatus). This shouldn't happen - check what went wrong")
        }
    }
    
    // The view before the game starts while still waiting for all players to respond to the invitation
    func waitingForInvitationResponses(for game: Game) {
        waitingLabel.text = "Waiting for all players to respond so that the game can start"
        
        // Set up the tableview
        waitingForTableView.delegate = self
        waitingForTableView.dataSource = self
        waitingForTableView.register(UITableViewCell.self, forCellReuseIdentifier: "playerCell")
    }
    
    // The view that non-lead players see while the lead player is drawing
    func waitingForDrawing(for game: Game) {
        waitingLabel.text = "Waiting for \(game.leadPlayerName) to finish drawing a funny picture"
        
        // Hide the tableview
        waitingForTableView.isHidden = true
    }
    
    // The view that lead players and non-lead players who have submitted captions see while waiting for all the captions to be submitted
    func waitingForCaptions(for game: Game) {
        waitingLabel.text = "Waiting for all captions to be submitted"
        
        // Hide the tableview of which players have submitted captions from the lead player
        if game.leadPlayer == UserController.shared.currentUser?.reference {
            waitingForTableView.isHidden = true
        } else {
            // Set up the tableview so that non-lead players can see it
            waitingForTableView.delegate = self
            waitingForTableView.dataSource = self
            waitingForTableView.register(UITableViewCell.self, forCellReuseIdentifier: "playerCell")
        }
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
}

// MARK: - TableView Delegate

extension WaitingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return game?.players.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath)
        
        guard let playerName = game?.playersNames[indexPath.row],
            let playerStatus = game?.playersStatus[indexPath.row]
            else { return cell }
        cell.textLabel?.text = playerName
        cell.detailTextLabel?.text = playerStatus.asString
        
        return cell
    }
}
