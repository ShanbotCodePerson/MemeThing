//
//  GameOverViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/5/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class GameOverViewController: UIViewController, HasAGameObject {
    
    // MARK: - Outlets
    
    @IBOutlet weak var winnerNameLabel: UILabel!
    @IBOutlet weak var resultsTableView: UITableView!
    @IBOutlet weak var exitGameButton: UIButton!
    @IBOutlet weak var playAgainButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    var gameID: String?
    var game: Game? { GameController.shared.currentGames?.first(where: { $0.recordID.recordName == gameID }) }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    // MARK: - Helper Methods
    
    // Helper methods to disable the UI while the data is loading and reenable it when it's finished
    func disableUI() {
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
        
        exitGameButton.deactivate()
        playAgainButton.deactivate()
    }
    
    func enableUI() {
        exitGameButton.activate()
        playAgainButton.activate()
        
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        view.backgroundColor = .background
        
        guard let game = game else { return }
        
        winnerNameLabel.text = game.gameStatusDescription
        
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.register(ThreeLabelsTableViewCell.self, forCellReuseIdentifier: "playerCell")
        resultsTableView.register(UINib(nibName: "ThreeLabelsTableViewCell", bundle: nil), forCellReuseIdentifier: "playerCell")
        resultsTableView.isUserInteractionEnabled = false
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        guard let game = game else { return transitionToStoryboard(named: .MainMenu) }
        
        // Remove the user from the game
        GameController.shared.leave(game) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Return to the main menu
                    self?.transitionToStoryboard(named: .MainMenu)
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    @IBAction func exitGameButtonTapped(_ sender: UIButton) {
        guard let game = game else { return }
        
        // Remove the user from the game
        GameController.shared.leave(game) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Return to the main menu
                    self?.transitionToStoryboard(named: .MainMenu)
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    @IBAction func playAgainButtonTapped(_ sender: UIButton) {
        guard let oldGame = game else { return }
        
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Don't allow the user to interact with the screen while the data is loading
        disableUI()
        
        // Start a new game from the data in the old game
        GameController.shared.newGame(from: oldGame) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let game):
                    // Transition to the waiting view
                    self?.transitionToStoryboard(named: .Waiting, with: game)
                case .failure(let error):
                    // Print and display the error and reset the UI
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                    self?.enableUI()
                }
            }
        }
    }
}

// MARK: - TableView Methods

extension GameOverViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return game?.activePlayers.values.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath) as? ThreeLabelsTableViewCell else { return UITableViewCell() }
        
        guard let game = game else { return cell }
        let player = game.sortedPlayers[indexPath.row]
        cell.setUpUI(firstText: player.name, secondText: "Points: \(player.points)")
        
        return cell
    }
}
