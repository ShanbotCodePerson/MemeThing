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
    @IBOutlet weak var navigationBar: UINavigationItem!
    
    // MARK: - Properties
    
    var gameID: String?
    var game: Game? { SavedGameController.finishedGames.first(where: { $0.recordID.recordName == gameID }) }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
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
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func exitGameButtonTapped(_ sender: UIButton) {
        // Delete the game from CoreData
        guard let game = game else { return }
        SavedGameController.delete(game)
        
        // Return to the main menu
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func playAgainButtonTapped(_ sender: UIButton) {
        guard let game = game else { return }
        
        // Fetch the players who participated in the previous game
        GameController.shared.fetchPlayers(from: game.activePlayersReferences.map({ $0.recordID })) { [weak self] (result) in
            switch result {
            case .success(let players):
                // Create a new game with all the previous (active) players
                // FIXME: - need some way to prevent multiple users clicking this button at the same time
                GameController.shared.newGame(players: players) { (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let game):
                            // Delete the finished game from the CoreData
                            SavedGameController.delete(game)
                            
                            // Transition to the waiting view
                            self?.transitionToStoryboard(named: StoryboardNames.waitingView, with: game)
                        case .failure(let error):
                            // Print and display the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            self?.presentErrorAlert(error)
                        }
                    }
                }
            case .failure(let error):
                // Print and display the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                DispatchQueue.main.async { self?.presentErrorAlert(error) }
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
