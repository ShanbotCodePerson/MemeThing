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

extension UIViewController {
    
    // MARK: - Navigation
    
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
        
        self.present(initialVC, animated: false)
    }
    
    func transitionToStoryboard(named storyboard: StoryboardNames, with game: Game) {
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
        
        self.present(initialVC, animated: false)
    }
    
    func presentPopoverStoryboard(named storyboard: StoryboardNames, with game: Game) {
        let storyboard = UIStoryboard(name: storyboard.rawValue, bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() as? HasAGameObject else { return }
        initialVC.gameID = game.recordID
        initialVC.modalPresentationStyle = .overFullScreen
        initialVC.modalTransitionStyle = .crossDissolve
        self.present(initialVC, animated: true)
    }
    
    // MARK: - Alerts
    
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
