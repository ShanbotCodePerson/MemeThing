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
    var game: FinishedGame? { FinishedGameController.shared.finishedGames.first(where: { $0.recordID == gameID }) }
    
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
        FinishedGameController.shared.delete(game)
        
        // Return to the main menu
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func playAgainButtonTapped(_ sender: UIButton) {
        // TODO: - delete the current game object but not before using its player data to create a new game
        // Fetch the players who participated in the previous game
        // TODO: - active players only?
        
        // Delete the game from CoreData
        guard let game = game else { return }
        
        // Transition to the waiting view
//        transitionToStoryboard(named: StoryboardNames.waitingView, with: <#T##Game#>)
    }
}

// MARK: - TableView Methods

extension GameOverViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return game?.numActivePlayers ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath) as? ThreeLabelsTableViewCell else { return UITableViewCell() }
        
        guard let game = game else { return cell }
        let player = game.sortedPlayers[indexPath.row]
        cell.setUpUI(firstText: player.name, secondText: "Points: \(player.points)")
        
        return cell
    }
}
