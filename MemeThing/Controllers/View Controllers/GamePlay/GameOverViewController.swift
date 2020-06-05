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
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func playAgainButtonTapped(_ sender: UIButton) {
        // TODO: - delete the current game object but not before using its player data to create a new game
    }
}
