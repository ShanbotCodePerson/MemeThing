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
    
    // MARK: - Properties
    
    var game: Game?
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        guard let game = game else { return }
        
        winnerNameLabel.text = game.gameStatusDescription
        
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.register(ThreeLabelsTableViewCell.self, forCellReuseIdentifier: "playerCell")
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func playAgainButtonTapped(_ sender: UIButton) {
        // TODO: - delete the current game object but not before using its player data to create a new game
    }
}

// MARK: - TableView Methods

extension GameOverViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return game?.players.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath) as? ThreeLabelsTableViewCell else { return UITableViewCell() }
        
        guard let game = game else { return cell }
        cell.firstLabel.text = game.playersNames[indexPath.row]
        cell.secondLabel.text = "Points: \(game.playersPoints[indexPath.row])"
        cell.thirdLabel.isHidden = true
        
        return cell
    }
}
