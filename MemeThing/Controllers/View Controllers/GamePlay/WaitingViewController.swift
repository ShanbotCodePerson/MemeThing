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
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    // MARK: - Properties
    
    var gameID: String?
    var game: Game? { GameController.shared.currentGames?.first(where: { $0.recordID.recordName == gameID }) }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        // FIXME: - do I have to remove these observers upon deinit?
        // Set up the observers to listen for notifications telling the view to reload its data
        NotificationCenter.default.addObserver(self, selector: #selector(refreshPage(_:)), name: updateWaitingView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(gameStarting(_:)), name: toNewRound, object: nil)
        
        // Set up the observers to listen for notifications telling the view to transition to a new page
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: toCaptionsView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: toResultsView, object: nil)
        
        // Display the leaderboard on top of the screen
        guard let game = game else { return }
        presentLeaderboard(with: game)
        // FIXME: - this doesn't work and also need to call it at appropriate time and also in drawing view(?)
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        view.backgroundColor = .background
        
        guard let game = game else { return }
        
        waitingLabel.text = game.gameStatusDescription
        
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
        // Set up the tableview
        waitingForTableView.delegate = self
        waitingForTableView.dataSource = self
        waitingForTableView.register(ThreeLabelsTableViewCell.self, forCellReuseIdentifier: "playerCell")
    }
    
    // The view that non-lead players see while the lead player is drawing
    func waitingForDrawing(for game: Game) {
        // Hide the tableview
        waitingForTableView.isHidden = true
    }
    
    // The view that lead players and non-lead players who have submitted captions see while waiting for all the captions to be submitted
    func waitingForCaptions(for game: Game) {
        // Hide the tableview of which players have submitted captions from the lead player
        if game.leadPlayer == UserController.shared.currentUser?.reference {
            waitingForTableView.isHidden = true
        } else {
            // Set up the tableview so that non-lead players can see it
            waitingForTableView.delegate = self
            waitingForTableView.dataSource = self
            waitingForTableView.register(ThreeLabelsTableViewCell.self, forCellReuseIdentifier: "playerCell")
        }
    }
    
    // MARK: - Respond to Notifications
    
    // Update the page with new data
    @objc func refreshPage(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID.recordName else { return }
        
        // Refresh the page
        DispatchQueue.main.async { self.waitingForTableView.reloadData() }
    }
    
    // Navigate to a different view
    @objc func transitionToNewPage(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID.recordName else { return }
        
        // Transition to the relevant view based on the type of update
        DispatchQueue.main.async {
            if sender.name == toCaptionsView {
                self.transitionToStoryboard(named: StoryboardNames.captionView, with: game)
            }
            else if sender.name == toResultsView {
                self.transitionToStoryboard(named: StoryboardNames.resultsView, with: game)
            }
        }
    }
    
    // Either update the page or navigate to a different view based on whether the current user is the lead player or not
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
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func dotsButtonTapped(_ sender: UIBarButtonItem) {
    }
}

// MARK: - TableView Delegate

extension WaitingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return game?.players.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath) as? ThreeLabelsTableViewCell else { return UITableViewCell() }
        
        guard let game = game else { return cell }
        // FIXME: - why are the outlets nil??
//        cell.setUpUI(game.playersNames[indexPath.row],
//                     game.playersStatus[indexPath.row].asString,
//                     "Points: \(game.playersPoints[indexPath.row])")
        
        return cell
    }
}
