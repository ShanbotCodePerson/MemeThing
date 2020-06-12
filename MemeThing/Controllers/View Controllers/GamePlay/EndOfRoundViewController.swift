//
//  EndOfRoundViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/12/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class EndOfRoundViewController: UIViewController, HasAGameObject {
    
    // MARK: - Outlets
    
    @IBOutlet weak var winnerLabel: UILabel!
    @IBOutlet weak var memeImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    
    // MARK: - Properties
    
    var gameID: String?
    var game: Game? { GameController.shared.currentGames?.first(where: { $0.recordID.recordName == gameID }) }
    var nextDestination: String?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        
        // Set up the observer to listen for notifications in case the user has left this page open too long and the game is moving on, or if the game has ended
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: toCaptionsView, object: nil)
         NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: toGameOver, object: nil)
    }
    
    // MARK: - Respond to Notifications
    
    @objc func transitionToNewPage(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID.recordName else { return }
        
        // Transition to the captions view if the game has moved on, or to the main menu if the game has ended
        DispatchQueue.main.async {
            if sender.name == toCaptionsView {
                self.transitionToStoryboard(named: StoryboardNames.captionView, with: game)
            }
            else if sender.name == toGameOver {
                self.transitionToStoryboard(named: StoryboardNames.gameOverView, with: game)
            }
        }
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        
        guard let game = game, let memeReference = game.memes?.last else { return }
        
        // Fetch the meme
        MemeController.shared.fetchMeme(from: memeReference) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let meme):
                    // Set the image view
                    self?.memeImageView.image = meme.photo
                    
                    // Fetch the winning caption
                    MemeController.shared.fetchWinningCaption(for: meme) { (result) in
                        print("got here to \(#function) and fetched winning caption")
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let caption):
                                // Set the text of the caption label
                                self?.captionLabel.text = caption.text
                                
                                // Get the name of the user from the game object to display in the winner's name label
                                let name = game.getName(of: caption.author)
                                self?.winnerLabel.text = "Congratulations \(name) for having the best caption!"
                                
                                // TODO: - don't need subscriptions to captions, just handle points here?
                                guard let currentUser = UserController.shared.currentUser else { return }
                                if caption.author.recordID.recordName == currentUser.reference.recordID.recordName {
                                    print("got here to updating current user's points")
                                    UserController.shared.update(currentUser, points: 1) { (result) in
                                        // TODO: - show alerts?
                                        switch result {
                                        case .success(_):
                                            print("should have incremented users points, now is \(currentUser.points)")
                                        case .failure(let error):
                                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                        }
                                    }
                                }
                                
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
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func continueButtonTapped(_ sender: UIButton) {
        guard let game = game, let nextDestination = nextDestination else { return }
        transitionToStoryboard(named: nextDestination, with: game)
    }
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
         guard let game = game, let nextDestination = nextDestination else { return }
        transitionToStoryboard(named: nextDestination, with: game)
    }
}