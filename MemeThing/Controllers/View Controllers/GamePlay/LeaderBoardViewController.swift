//
//  LeaderboardViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/5/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class LeaderboardViewController: UIViewController, HasAGameObject {
    
    // MARK: - Outlets
    
    @IBOutlet weak var gameStatusView: UIView!
    @IBOutlet weak var gameStatusLabel: UILabel!
    @IBOutlet weak var playersTableView: SelfSizingTableView!
    
    // MARK: - Properties
    
    var gameID: String?
    var game: Game? { GameController.shared.currentGames?.first(where: { $0.recordID == gameID }) }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Set up the observers to listen for notifications telling the view to transition to a new page
        NotificationCenter.default.addObserver(self, selector: #selector(closeSelf(_:)), name: closeLeaderboard, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: toCaptionsView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: toResultsView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: toGameOver, object: nil)
    }
    
    // MARK: - Respond to Notifications
    
    @objc func closeSelf(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID else { return }
        
        DispatchQueue.main.async { self.dismiss(animated: true) }
    }
    
    @objc func transitionToNewPage(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID else { return }
        
        // Transition to the relevant view based on the type of update
        DispatchQueue.main.async {
            if sender.name == toCaptionsView {
                self.transitionToStoryboard(named: .AddCaption, with: game)
            }
            else if sender.name == toResultsView {
                self.transitionToStoryboard(named: .ViewResults, with: game)
            }
            else if sender.name == toGameOver {
                self.transitionToStoryboard(named: .GameOver, with: game)
            }
        }
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        
        guard let game = game else { return }
        
        gameStatusLabel.text = game.gameStatusDescription
        
        playersTableView.maxHeight = view.frame.height * 0.5
        playersTableView.addCornerRadius()
        playersTableView.addBorder(width: 2)
        playersTableView.delegate = self
        playersTableView.dataSource = self
        playersTableView.register(ThreeLabelsTableViewCell.self, forCellReuseIdentifier: "playerCell")
        playersTableView.register(UINib(nibName: "ThreeLabelsTableViewCell", bundle: nil), forCellReuseIdentifier: "playerCell")
    }
    
    // MARK: - Actions
    
    @IBAction func quitButtonTapped(_ sender: UIButton) {
        guard let game = game else { return }
        
        // Present an alert to confirm the user really wants to quit the game
        presentConfirmAlert(title: "Are you sure?", message: "Are you sure you want to quit the game?") {
            // If the user clicks "confirm," quit the game and return to the main menu
            GameController.shared.quit(game) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Return to the main menu
                        self?.transitionToStoryboard(named: .MainMenu)
                    case .failure(let error):
                        // Print and present the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true)
    }
}

// MARK: - TableView Methods

extension LeaderboardViewController: UITableViewDelegate, UITableViewDataSource {
    
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
