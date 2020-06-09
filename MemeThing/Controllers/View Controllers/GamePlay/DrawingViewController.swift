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
    
    // MARK: - Properties
    
    var game: Game?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Display the leaderboard unless the game is just starting
        guard let game = game else { return }
        if game.memes?.count ?? 0 > 0 {
            transitionToStoryboard(named: StoryboardNames.leaderboardView, with: game)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func undoButtonTapped(_ sender: UIButton) {
        canvasView.undoDraw()
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let game = game, let currentUser = UserController.shared.currentUser else { return }
        
        // Create the image from the canvas (hide the undo button first so that it isn't saved in the screenshot)
        undoButton.isHidden = true
        let image = canvasView.getImage()
        
        // Create the meme object and save it to the cloud
        MemeController.shared.createMeme(with: image, by: currentUser) { [weak self] (result) in
            switch result {
            case .success(let meme):
                // Add the meme to the game
                if var memes = game.memes {
                    memes.append(meme.reference)
                    game.memes = memes
                } else {
                    game.memes = [meme.reference]
                }
                
                // Update the game's status
                game.gameStatus = .waitingForCaptions
                // FIXME: - Make sure this change is reflected in the game in the SoT too
                
                // Update the player's status
                game.updateStatus(of: currentUser, to: .sentDrawing)
                
                // Save the game to the cloud
                // TODO: - better way than nested completions??
                GameController.shared.saveChanges(to: game) { (result) in
                    switch result {
                    case .success(_):
                        // Transition back to the waiting view until all the captions have been submitted
                        DispatchQueue.main.async {
                            self?.transitionToStoryboard(named: StoryboardNames.waitingView, with: game)
                        }
                    case .failure(let error):
                        // TODO: - better error handling in here
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    }
                }
            case .failure(let error):
                // TODO: - better error handling in here
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
    }
}
