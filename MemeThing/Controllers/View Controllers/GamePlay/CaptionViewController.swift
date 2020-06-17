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
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var keyboardHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    var gameID: String?
    var game: Game? { GameController.shared.currentGames?.first(where: { $0.recordID.recordName == gameID }) }
    var meme: Meme? { didSet { memeImageView.image =  meme?.photo } }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        captionTextField.delegate = self
        
        // Add an observer for when the keyboard appears or disappears
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        // Set up the observer to transition to the game over view in case the game ends prematurely
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: toGameOver, object: nil)
    }
    
    // MARK: - Respond to Notifications
    
    @objc func keyboardNotification(_ sender: NSNotification) {
        guard let userInfo = sender.userInfo else { return }
        
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let endFrameY = endFrame?.origin.y ?? 0
        let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
        if endFrameY >= UIScreen.main.bounds.size.height {
            self.keyboardHeightLayoutConstraint?.constant = 8.0
        } else {
            if let height = endFrame?.size.height {
                self.keyboardHeightLayoutConstraint?.constant = height - sendButton.frame.height
            }
        }
        
        UIView.animate(withDuration: duration, delay: TimeInterval(0), options: animationCurve, animations: { self.view.layoutIfNeeded() }, completion: nil)
    }
    
    @objc func transitionToNewPage(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID.recordName else { return }
        
        // Transition to the relevant view based on the type of update
        DispatchQueue.main.async {
            if sender.name == toGameOver {
                self.transitionToStoryboard(named: StoryboardNames.gameOverView, with: game)
            }
        }
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        view.backgroundColor = .background
        loadingIndicator.isHidden = true
        
        guard let game = game, let memeReference = game.memes?.last else { return }
        
        // Fetch the meme object
        MemeController.shared.fetchMeme(from: memeReference) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let meme):
                    // Save the meme object
                    self?.meme = meme
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    // Helper methods to disable the UI while the data is loading and reenable it when it's finished
    func disableUI() {
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
        
        captionTextField.isUserInteractionEnabled = false
        sendButton.deactivate()
    }
    
    func enableUI() {
        captionTextField.isUserInteractionEnabled = true
        sendButton.activate()
        
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func dotsButtonTapped(_ sender: UIBarButtonItem) {
        guard let game = game else { return }
        presentPopoverStoryboard(named: StoryboardNames.leaderboardView, with: game)
    }
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        print("got here to \(#function)")
        // Close the keyboard
        captionTextField.resignFirstResponder()
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        saveCaption()
    }
    
    // MARK: - Helper Method
    
    func saveCaption() {
        guard let game = game, let meme = meme, let currentUser = UserController.shared.currentUser,
            let captionText = captionTextField.text else { return }
        
        // Don't allow the user to interact with the screen while the save is in progress
        disableUI()
        
        // Add the caption to the meme object
        MemeController.shared.createCaption(for: meme, by: currentUser, with: captionText, in: game) { [weak self] (result) in
            switch result {
            case .success(_):
                // Update the player's status
                game.updateStatus(of: currentUser, to: .sentCaption)
                
                // Update the game's status if this was the final caption
                if game.allCaptionsSubmitted { game.gameStatus = .waitingForResult }
                
                // Save the updated game to the cloud
                GameController.shared.saveChanges(to: game) { (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            if game.allCaptionsSubmitted {
                                // Give some time for CloudKit to catch up
                                sleep(2)
                                
                                // Go to the results view if all captions have been submitted already
                                self?.transitionToStoryboard(named: StoryboardNames.resultsView, with: game)
                            } else {
                                // Transition back to the waiting view until all the captions have been submitted
                                self?.transitionToStoryboard(named: StoryboardNames.waitingView, with: game)
                            }
                        case .failure(let error):
                            // Print and display the error and reset the UI
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            self?.presentErrorAlert(error)
                            self?.enableUI()
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    // Print and display the error and reset the UI
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                    self?.enableUI()
                }
            }
        }
    }
}

// MARK: - Text Field Delegate

extension CaptionViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Dismiss the keyboard
        textField.resignFirstResponder()
        
        // Save the caption
        saveCaption()
        
        return true
    }
}
