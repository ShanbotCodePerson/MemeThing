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
    @IBOutlet weak var nextUpLabel: UILabel!
    
    // MARK: - Properties
    
    var gameID: String?
    var game: Game? { GameController.shared.currentGames?.first(where: { $0.recordID == gameID }) }
    var nextDestination: StoryboardNames?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Set up the observer to listen for notifications in case the user has left this page open too long and the game is moving on, or if the game has ended
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: .toCaptionsView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: .toGameOver, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: .toMainMenu, object: nil)
        
        // Set up the observers to listen for responses to push notifications
        setUpObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .toCaptionsView, object: nil)
        NotificationCenter.default.removeObserver(self, name: .toGameOver, object: nil)
        NotificationCenter.default.removeObserver(self, name: .toMainMenu, object: nil)
        removeObservers()
    }
    
    // MARK: - Respond to Notifications
    
    @objc func transitionToNewPage(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID else { return }
        
        // Transition to the captions view if the game has moved on, or to the main menu if the game has ended
        DispatchQueue.main.async {
            if sender.name == .toCaptionsView {
                self.transitionToStoryboard(named: .AddCaption, with: game)
            }
            else if sender.name == .toGameOver {
                self.transitionToStoryboard(named: .GameOver, with: game)
            }
            else if sender.name == .toMainMenu {
                self.transitionToStoryboard(named: .MainMenu)
            }
        }
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        //Beth added:
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor.cyan.cgColor, UIColor.blue.cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
                
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        //captionLabel.backgroundColor = .purpleAccent
        memeImageView.addCornerRadius(10)
        
        guard let game = game, let memeReference = game.memes?.last else { return }
        
        // Show the loading icon
        view.startLoadingIcon()
        
        // Fetch the meme
        MemeController.shared.fetchMeme(from: memeReference) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let meme):
                    // Set the image view
                    self?.memeImageView.image = meme.image
                    self?.memeImageView.addCornerRadius(10)

                    
                    // Fetch the winning caption
                    MemeController.shared.fetchWinningCaption(for: meme) { (result) in
                        DispatchQueue.main.async {
                            // Hide the loading icon
                            self?.view.stopLoadingIcon()
                            
                            switch result {
                            case .success(let caption):
                                // Get the name of the user from the game object to display in the winner's name label
                                let name = game.getName(of: caption.authorID)
                                self?.winnerLabel.text = "Congratulations, \(name), for having the best caption!"
                                
                                // Set the text/UI of the caption label
                                self?.captionLabel.text = caption.text
                                self?.captionLabel.setUpViews(borderWidth: 2, backgroundColor: .orangeAccent, opacity: 1)
                                
                                // Set the text of the label telling the users what's up next
                                if let gameWinner = game.gameWinner {
                                    self?.nextUpLabel.text = "The game is over and \(gameWinner) has won!"
                                } else {
                                    if game.leadPlayerID == UserController.shared.currentUser?.recordID {
                                         self?.nextUpLabel.text = "Next, it is your turn to draw a meme!"
                                    } else {
                                        self?.nextUpLabel.text = "Next, it is \(game.leadPlayerName)'s turn to draw a meme!"
                                    }
                                }
                                
                                guard let currentUser = UserController.shared.currentUser else { return }
                                if caption.authorID == currentUser.recordID {
                                    UserController.shared.update(currentUser, points: 1) { (result) in
                                        // TODO: - show alerts? tell winning user they earned a point?
                                        switch result {
                                        case .success(_):
                                            // TODO: - display an alert or update the ui somehow telling the user they got a point
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
                    // Print and display the error and hide the loading icon
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.view.stopLoadingIcon()
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
