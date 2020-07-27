//
//  DrawingViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/28/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class DrawingViewController: UIViewController, HasAGameObject {
    
    // MARK: - Outlets
    
    @IBOutlet weak var canvasView: CanvasView!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var sendButton: UIButton!
    
    // MARK: - Properties
    
    var gameID: String?
    var game: Game? { GameController.shared.currentGames?.first(where: { $0.recordID == gameID }) }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        
        // Set up the observer to transition to the game over view in case the game ends prematurely
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: .toGameOver, object: nil)
        
        // Set up the observers to listen for responses to push notifications
        setUpObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .toGameOver, object: nil)
        removeObservers()
    }
    
    // MARK: - Set Up Views
    
    //Beth added:
    func setUpViews() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor.cyan.cgColor, UIColor.blue.cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // MARK: - Respond to Notifications
    
    @objc func transitionToNewPage(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID else { return }
        
        // Transition to the relevant view based on the type of update
        DispatchQueue.main.async {
            if sender.name == .toGameOver { self.transitionToStoryboard(named: .GameOver, with: game) }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: .MainMenu)
    }
    
    @IBAction func dotsButtonTapped(_ sender: UIBarButtonItem) {
        guard let game = game else { return }
        presentPopoverStoryboard(named: .Leaderboard, with: game)
    }
    
    @IBAction func undoButtonTapped(_ sender: UIButton) {
        canvasView.undoDraw()
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let game = game, let currentUser = UserController.shared.currentUser else { return }
        
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Create the image from the canvas (hide the undo button first so that it isn't saved in the screenshot)
        undoButton.isHidden = true
        let image = canvasView.getImage()
        
        // Show the loading icon
        view.startLoadingIcon()
        
        // Create the meme object and save it to the cloud
        MemeController.shared.createMeme(in: game, with: image, by: currentUser) { [weak self] (result) in
            switch result {
            case .success(let meme):
                // Add the meme to the game
                if game.memes?.append(meme.recordID) == nil { game.memes = [meme.recordID] }
                
                // Update the game's status
                game.gameStatus = .waitingForCaptions
                
                // Update the player's status
                game.updateStatus(of: currentUser, to: .sentDrawing)
                
                // Save the game to the cloud
                 GameController.shared.saveChanges(to: game) { (result) in
                    DispatchQueue.main.async {
                        // Hide the loading icon
                        self?.view.stopLoadingIcon()
                        
                        switch result {
                        case .success(_):
                            // Transition back to the waiting view until all the captions have been submitted
                            self?.transitionToStoryboard(named: .Waiting, with: game)
                        case .failure(let error):
                            // Print and display the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            self?.presentErrorAlert(error)
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    // Print and display the error and hide the loading icon
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.view.stopLoadingIcon()
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
}
