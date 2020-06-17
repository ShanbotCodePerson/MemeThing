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
    var game: Game? { GameController.shared.currentGames?.first(where: { $0.recordID.recordName == gameID }) }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        
        // FIXME: - need to have all observers in here so that user continues with game as needed even if viewing leaderboard while notification comes in
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
                        self?.transitionToStoryboard(named: StoryboardNames.mainMenu)
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
