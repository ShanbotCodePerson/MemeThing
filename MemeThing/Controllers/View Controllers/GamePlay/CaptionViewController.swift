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
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var memeImageView: MemeImageView!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var keyboardHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    
    // MARK: - Properties
    
    var gameID: String?
    var game: Game? { GameController.shared.currentGames?.first(where: { $0.recordID == gameID }) }
    var meme: Meme? { didSet { memeImageView.image =  meme?.image } }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        captionTextField.delegate = self
        
        // Add an observer for when the keyboard appears or disappears
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        // Set up the observer to transition to the game over view in case the game ends prematurely
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: .toGameOver, object: nil)
        
        // Set up the observers to listen for responses to push notifications
        setUpObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .toGameOver, object: nil)
        removeObservers()
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
            gameID == game.recordID else { return }
        
        // Transition to the relevant view based on the type of update
        DispatchQueue.main.async {
            if sender.name == .toGameOver {
                self.transitionToStoryboard(named: .GameOver, with: game)
            }
        }
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        guard let game = game, let memeID = game.memes?.last else { return }
        
        // Show the loading icon
        view.startLoadingIcon()
        
        // Fetch the meme object
        MemeController.shared.fetchMeme(from: memeID) { [weak self] (result) in
            DispatchQueue.main.async {
                // Hide the loading icon
                self?.view.stopLoadingIcon()
                
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
        
        //Beth added:
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.backgroundView.bounds
        gradientLayer.colors = [UIColor.cyan.cgColor, UIColor.blue.cgColor]
        self.backgroundView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: .MainMenu)
    }
    
    @IBAction func dotsButtonTapped(_ sender: UIBarButtonItem) {
        guard let game = game else { return }
        presentPopoverStoryboard(named: .Leaderboard, with: game)
    }
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        print("got here to \(#function)")
        // Close the keyboard
        captionTextField.resignFirstResponder()
    }
    
    @IBAction func reportContentButton(_ sender: UIButton) {
        guard let currentUser = UserController.shared.currentUser,
            let meme = meme
            else { return }
        
        presentTextFieldAlert(title: "Report User?", message: "Report the author of this drawing for offensive or inappropriate content", textFieldPlaceholder: "Describe problem...") { (complaint) in
            
            // Form the body of the report
            let content = "Report filed by user with id \(currentUser.recordID) on \(Date()) regarding a drawing made by user with id \(meme.authorID). User description of problem is: \(complaint)"
            
            // Save the complaint to the cloud to be reviewed later
            ComplaintController.createComplaint(with: content, image: meme.image) { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Display the success
                        self?.presentAlert(title: "Report Sent", message: "Your report has been sent and will be reviewed as soon as possible")
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        saveCaption()
    }
    
    // MARK: - Helper Method
    
    func saveCaption() {
        guard let game = game, let meme = meme, let currentUser = UserController.shared.currentUser,
            let captionText = captionTextField.text else { return }
        
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Show the loading icon
        view.startLoadingIcon()
        
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
                    // Hide the loading icon
                    self?.view.stopLoadingIcon()
                    
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            if game.allCaptionsSubmitted {
                                // Go to the results view if all captions have been submitted already
                                self?.transitionToStoryboard(named: .ViewResults, with: game)
                            } else {
                                // Transition back to the waiting view until all the captions have been submitted
                                self?.transitionToStoryboard(named: .Waiting, with: game)
                            }
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
