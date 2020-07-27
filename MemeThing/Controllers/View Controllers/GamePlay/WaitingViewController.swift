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
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var waitingLabel: UILabel!
    @IBOutlet weak var waitingForTableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    // MARK: - Properties
    
    var gameID: String?
    var game: Game? { GameController.shared.currentGames?.first(where: { $0.recordID == gameID }) }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Set up the observers to listen for notifications telling the view to reload its data
        NotificationCenter.default.addObserver(self, selector: #selector(refreshPage(_:)), name: .updateWaitingView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(gameStarting(_:)), name: .toNewRound, object: nil)
        
        // Set up the observers to listen for notifications telling the view to transition to a new page
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: .toCaptionsView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: .toResultsView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: .toGameOver, object: nil)
        
        // Set up the observers for responding to push notifications
        setUpObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .updateWaitingView, object: nil)
        NotificationCenter.default.removeObserver(self, name: .toNewRound, object: nil)
        NotificationCenter.default.removeObserver(self, name: .toCaptionsView, object: nil)
        NotificationCenter.default.removeObserver(self, name: .toResultsView, object: nil)
        NotificationCenter.default.removeObserver(self, name: .toGameOver, object: nil)
        removeObservers()
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        guard let game = game else { return }
        
        waitingLabel.text = game.gameStatusDescription
        
        // Set up the view based on the status of the game
        switch game.gameStatus {
        case .waitingForPlayers:
            setUpTableView()
        case .waitingForDrawing:
            waitingForTableView.isHidden = true
        case .waitingForCaptions:
            if game.leadPlayerID == UserController.shared.currentUser?.recordID {
                waitingForTableView.isHidden = true
            } else { setUpTableView() }
        case .waitingForResult:
            transitionToStoryboard(named: .ViewResults, with: game)
        case .gameOver:
            transitionToStoryboard(named: .GameOver, with: game)
        default:
            print("In waiting view and game status is \(game.gameStatus). This shouldn't happen - check what went wrong")
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.frame
        gradientLayer.colors = [UIColor.cyan.cgColor, UIColor.blue.cgColor]
        self.backgroundView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // Set up the tableview if it's needed
    func setUpTableView() {
        waitingForTableView.delegate = self
        waitingForTableView.dataSource = self
        waitingForTableView.register(ThreeLabelsTableViewCell.self, forCellReuseIdentifier: "playerCell")
        waitingForTableView.register(UINib(nibName: "ThreeLabelsTableViewCell", bundle: nil), forCellReuseIdentifier: "playerCell")
    }
    
    // MARK: - Respond to Notifications
    
    // Update the page with new data
    @objc func refreshPage(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID else { return }
        
        // Refresh the page
        DispatchQueue.main.async {
            self.waitingLabel.text = game.gameStatusDescription
            self.waitingForTableView.reloadData()
        }
    }
    
    // Navigate to a different view
    @objc func transitionToNewPage(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID else { return }
        
        // Transition to the relevant view based on the type of update
        DispatchQueue.main.async {
            if sender.name == .toCaptionsView {
                self.transitionToStoryboard(named: .AddCaption, with: game)
            }
            else if sender.name == .toResultsView {
                self.transitionToStoryboard(named: .ViewResults, with: game)
            }
            else if sender.name == .toGameOver {
                self.transitionToStoryboard(named: .GameOver, with: game)
            }
        }
    }
    
    // Either update the page or navigate to a different view based on whether the current user is the lead player or not
    @objc func gameStarting(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID else { return }
        
        // If the current user is the lead player, transition to the drawing view
        DispatchQueue.main.async {
            if game.leadPlayerID == UserController.shared.currentUser?.recordID {
                self.transitionToStoryboard(named: .Drawing, with: game)
            } else {
                // Otherwise, refresh the waiting view to reflect that the game is starting
                self.setUpViews()
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: .MainMenu)
    }
    
    @IBAction func dotsButtonTapped(_ sender: UIBarButtonItem) {
        guard let game = game else { return }
        presentPopoverStoryboard(named: .Leaderboard, with: game)
    }
}

// MARK: - TableView Delegate

extension WaitingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return game?.activePlayers.values.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath) as? ThreeLabelsTableViewCell else { return UITableViewCell() }
        
        guard let game = game else { return cell }
        let player = game.sortedPlayers[indexPath.row]
        cell.setUpUI(firstText: player.name, secondText: player.status.asString, thirdText: "Points: \(player.points)")
        
        return cell
    }
}
