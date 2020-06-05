//
//  ResultsViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/28/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class ResultsViewController: UIViewController, HasAGameObject {
    
    // MARK: - Outlets
    
    @IBOutlet weak var memeImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var chooseWinnerButton: UIButton!
    
    // MARK: - Properties
    
    var game: Game?
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the observers to listen for notifications telling the view to transition to a new page
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: winningCaptionChosen, object: nil)
    }
    
    // MARK: - Set Up UI
    
    @objc func transitionToNewPage(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID.recordName else { return }
        
        // Transition to the relevant view based on the type of update
//        transitionToStoryboard(named: StoryboardNames., with: game)
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func chooseWinnerButtonTapped(_ sender: UIButton) {
        // TODO: - make relevant changes to game, user, meme, caption, etc
        // TODO: - save game object
        // TODO: - transition to waiting view controller, present the leaderboard view
    }
}
