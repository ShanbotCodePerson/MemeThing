//
//  WaitingViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/28/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class WaitingViewController: UIViewController {
    
    // MARK: - Properties
    
    var game: Game?
    
    // MARK: - Outlets
    
    @IBOutlet weak var waitingLabel: UILabel!
    @IBOutlet weak var waitingForTableView: UITableView!
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Set up the observers to listen for notifications telling the view to reload its data
        NotificationCenter.default.addObserver(self, selector: #selector(setUpViews), name: playerRespondedToGameInvite, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setUpViews), name: playerSentCaption, object: nil)
        // TODO: - either create one notification name or separate into different functionality to respond to these notifications
    }
    
    // MARK: - Set Up UI
    
    @objc func setUpViews() {
        guard let game = game else { return }
        
        DispatchQueue.main.async {
            // Only display the tableview if the game status is // TODO: - figure this out
            if game.gameStatus == .waitingForPlayers { // FIXME: - get proper set of game status's
                // TODO: - update waiting label at top
                self.waitingForTableView.delegate = self
                self.waitingForTableView.dataSource = self
                self.waitingForTableView.register(WaitingTableViewCell.self, forCellReuseIdentifier: "playerCell")
            } else {
                // TODO: - update waiting label at top
                self.waitingForTableView.isHidden = true
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "MainMenu", bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() else { return }
        initialVC.modalPresentationStyle = .fullScreen
        self.present(initialVC, animated: true)
    }
}

// MARK: - TableView Delegate

extension WaitingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return game?.playerInfo.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath) as? WaitingTableViewCell else { return UITableViewCell() }
        
        guard let playerInfo = game?.playerInfo[indexPath.row] else { return cell }
        cell.friendNameLabel.text = playerInfo.name
        cell.statusLabel.text = playerInfo.status.asString
        
        return cell
    }
}
