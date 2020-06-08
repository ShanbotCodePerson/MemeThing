//
//  CaptionViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/28/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class CaptionViewController: UIViewController, HasAGameObject {
    
    // MARK: - Outlets
    
    @IBOutlet weak var memeImageView: MemeImageView!
    @IBOutlet weak var captionTextField: UITextField!
    
    // MARK: - Properties
    
    var game: Game?
    var meme: Meme? { didSet { memeImageView.image =  meme?.photo } }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        guard let game = game, let memeReference = game.memes?.last else { return }
        
        // Fetch the meme object
        MemeController.shared.fetchMeme(from: memeReference) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let meme):
                    // Save the meme object
                    self?.meme = meme
                case .failure(let error):
                    // TODO: - better error handling here, present alert?
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorToUser(error)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let game = game, let meme = meme, let currentUser = UserController.shared.currentUser,
            let captionText = captionTextField.text else { return }
        
        // Add the caption to the meme object
        MemeController.shared.createCaption(for: meme, by: currentUser, with: captionText, in: game) { [weak self] (result) in
            switch result {
            case .success(_):
                // Update the player's status
                game.updateStatus(of: currentUser, to: .sentCaption)
                
                // Update the game's status if this was the final caption
                // FIXME: - this will probably break if the last two captions are submitted at the same time - need to confirm somewhere
                if game.allCaptionsSubmitted { game.gameStatus = .waitingForResult }
                
                // Save the updated game to the cloud
                GameController.shared.update(game) { (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            if game.allCaptionsSubmitted {
                                // Go to the results view if all captions have been submitted already
                                self?.transitionToStoryboard(named: StoryboardNames.resultsView, with: game)
                            } else {
                                // Transition back to the waiting view until all the captions have been submitted
                                self?.transitionToStoryboard(named: StoryboardNames.waitingView, with: game)
                            }
                        case .failure(let error):
                            // TODO: - better error handling here
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        }
                    }
                }
            case .failure(let error):
                // TODO: - better error handling here
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
    }
}
