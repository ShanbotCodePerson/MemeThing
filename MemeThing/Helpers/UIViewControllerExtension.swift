//
//  UIViewControllerExtension.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

// MARK: - Game Object Protocol

protocol HasAGameObject: UIViewController {
    var gameID: String? { get set }
}

// MARK: - Navigation

extension UIViewController {
    
    enum StoryboardNames: String  {
        case Main
        case MainMenu
        case CurrentGames
        case Friends
        case Waiting
        case Drawing
        case AddCaption
        case ViewResults
        case EndOfRound
        case Leaderboard
        case GameOver
    }
    
    func transitionToStoryboard(named storyboard: StoryboardNames, direction: CATransitionSubtype = .fromLeft) {
        // Make sure the user is not already on the given storyboard
        guard let currentStoryboard = self.storyboard?.value(forKey: "name") as? String,
            currentStoryboard != storyboard.rawValue
            else { return }
        
        // Initialize the storyboard
        let storyboard = UIStoryboard(name: storyboard.rawValue, bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() else { return }
        initialVC.modalPresentationStyle = .fullScreen
        
        // Make the transition look like navigating back through a navigation controller
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = .push
        transition.subtype = direction
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        
        // Present the storyboard
        self.present(initialVC, animated: false)
    }
    
    func transitionToStoryboardInNavController(named storyboard: StoryboardNames, direction: CATransitionSubtype = .fromLeft) {
        // Make sure the user is not already on the given storyboard
        guard let currentStoryboard = self.storyboard?.value(forKey: "name") as? String,
            currentStoryboard != storyboard.rawValue
            else { return }
        
        // Initialize the storyboard
        let storyboard = UIStoryboard(name: storyboard.rawValue, bundle: nil)
        let navigationStoryboard = UIStoryboard(name: StoryboardNames.MainMenu.rawValue, bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController(),
            let navigationVC = navigationStoryboard.instantiateInitialViewController() as? UINavigationController
            else { return }
        navigationVC.modalPresentationStyle = .fullScreen
        
        // Make the transition look like navigating back through a navigation controller
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = .push
        transition.subtype = direction
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        
        
        // Present the storyboard
        self.present(navigationVC, animated: false)
        navigationVC.pushViewController(initialVC, animated: true)
    }
    
    func transitionToStoryboard(named storyboard: StoryboardNames, with game: Game) {
        // Initialize the storyboard
        let storyboard = UIStoryboard(name: storyboard.rawValue, bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() as? HasAGameObject else { return }
        initialVC.gameID = game.recordID
        initialVC.modalPresentationStyle = .fullScreen
        
        // Make the transition look like navigating forward through a navigation controller
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = .push
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        
        // Present the storyboard
        self.present(initialVC, animated: false)
    }
    
    func presentPopoverStoryboard(named storyboard: StoryboardNames, with game: Game) {
        // Initialize the storyboard
        let storyboard = UIStoryboard(name: storyboard.rawValue, bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() as? HasAGameObject else { return }
        initialVC.gameID = game.recordID
        
        // Set the transition to appear in the middle of the screen
        initialVC.modalPresentationStyle = .overFullScreen
        initialVC.modalTransitionStyle = .crossDissolve
        
        // Initialize the storyboard
        self.present(initialVC, animated: true)
    }
}

// MARK: - Alerts

extension UIViewController {
    
    // Present an alert with a simple dismiss button to display a message to the user
    func presentAlert(title: String, message: String, completion: @escaping () -> Void = {}) {
        // Create the alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the dismiss button to the alert
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (_) in return completion() }))
        
        // Present the alert
        present(alertController, animated: true)
    }
    
    // Present an alert that the internet connection isn't working
    func presentInternetAlert() {
        presentAlert(title: "No Internet Connection", message: "You must be connected to the internet in order to use MemeThing. Please check your internet connection and try again")
    }
    
    // Present an alert with simple confirm or cancel buttons
    func presentConfirmAlert(title: String, message: String, cancelText: String = "Cancel", confirmText: String = "Confirm", completion: @escaping () -> Void) {
        // Create the alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the cancel button to the alert
        alertController.addAction(UIAlertAction(title: cancelText, style: .cancel))
        
        // Add the confirm button to the alert
        alertController.addAction(UIAlertAction(title: confirmText, style: .default, handler: { (_) in completion() }))
        
        // Present the alert
        present(alertController, animated: true)
    }
    
    // Present an alert with a text field to get some input from the user
    func presentTextFieldAlert(title: String, message: String, textFieldPlaceholder: String?, textFieldText: String? = nil, saveButtonTitle: String = "Save", completion: @escaping (String) -> Void) {
        // Create the alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the text field
        alertController.addTextField { (textField) in
            textField.placeholder = textFieldPlaceholder
            if let textFieldText = textFieldText {
                textField.text = textFieldText
            }
        }
        
        // Create the cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Create the save button
        let saveAction = UIAlertAction(title: saveButtonTitle, style: .default) { (_) in
            // Get the text from the text field
            guard let text = alertController.textFields?.first?.text, !text.isEmpty else { return }
            
            // Pass it to the helper function to handle sending the friend request
            completion(text)
        }
        
        // Add the buttons to the alert and present it
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        present(alertController, animated: true)
    }
    
    // Present an alert at the bottom of the screen to display an error to the user
    func presentErrorAlert(_ localizedError: LocalizedError) {
        // Create the alert controller
        let alertController = UIAlertController(title: "ERROR", message: localizedError.errorDescription, preferredStyle: .alert)
        
        // Add the dismiss button to the alert
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        // Present the alert
        present(alertController, animated: true)
    }
    func presentErrorAlert(_ error: Error) {
        // Create the alert controller
        let alertController = UIAlertController(title: "ERROR", message: error.localizedDescription, preferredStyle: .alert)
        
        // Add the dismiss button to the alert
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        // Present the alert
        present(alertController, animated: true)
    }
}

// MARK: - Notifications

extension UIViewController {
    
    // Set up or remove the notifications for any view controller to be able to respond to push notifications
    func setUpObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(toFriendsList), name: .toFriendsView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toGamesList), name: .toGamesView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toGameOver(_:)), name: .toGameOver, object: nil)
    }
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .toFriendsView, object: nil)
        NotificationCenter.default.removeObserver(self, name: .toGamesView, object: nil)
        NotificationCenter.default.removeObserver(self, name: .toGameOver, object: nil)
    }
    
    // Transition to the relevant storyboards in response to notifications
    @objc func toFriendsList() {
//        DispatchQueue.main.async { self.transitionToStoryboardInNavController(named: .Friends) }
    }
    @objc func toGamesList() {
//        DispatchQueue.main.async { self.transitionToStoryboardInNavController(named: .CurrentGames) }
    }
    @objc func toGameOver(_ sender: NSNotification) {
        print("trying to transition to game over view")
//        guard let gameID = sender.userInfo?["gameID"] as? String,
//            let game = GameController.shared.currentGames?.first(where: { $0.recordID == gameID })
//            else { return }
//        
//        DispatchQueue.main.async { self.transitionToStoryboard(named: .GameOver, with: game) }
    }
}
