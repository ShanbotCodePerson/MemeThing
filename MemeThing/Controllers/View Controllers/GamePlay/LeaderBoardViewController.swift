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
    
    @IBOutlet weak var gameStatusLabel: UILabel!
    @IBOutlet weak var playersTableView: UITableView!
    
    // MARK: - Properties
    
    var game: Game?
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        
        guard let game = game else { return }
        
        gameStatusLabel.text = game.gameStatusDescription
        
        playersTableView.delegate = self
        playersTableView.dataSource = self
        playersTableView.register(ThreeLabelsTableViewCell.self, forCellReuseIdentifier: "playerCell")
    }
    
    // MARK: - Actions
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}

// MARK: - TableView Methods

extension LeaderboardViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return game?.players.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       guard let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath) as? ThreeLabelsTableViewCell else { return UITableViewCell() }
        
        guard let game = game else { return cell }
        cell.firstLabel.text = game.playersNames[indexPath.row]
        cell.secondLabel.text = game.playersStatus[indexPath.row].asString
        cell.thirdLabel.text = "Points: \(game.playersPoints[indexPath.row])"
        
        return cell
    }
}
