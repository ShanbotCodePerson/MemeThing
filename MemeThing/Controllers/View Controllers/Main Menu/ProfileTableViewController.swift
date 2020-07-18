//
//  ProfileTableViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit
import Firebase

class ProfileTableViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    
    // MARK: - Properties
    
    var editingPassword = false
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeObservers()
    }
    
    // MARK: - Set Up Views
    
    func setUpViews() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        guard let user = UserController.shared.currentUser else { return }
        screenNameLabel.text = "Screen Name: \(user.screenName)"
        emailLabel.text = "Email: \(user.email)"
        pointsLabel.text = "Points: \(user.points)"
    }
    
    // MARK: - Actions
    
    @IBAction func editScreenNameButtonTapped(_ sender: UIButton) {
        guard let user = UserController.shared.currentUser else { return }
        
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Present the text field to allow the user to edit their name
        presentTextFieldAlert(title: "Edit Screen Name", message: "Edit your name as it will appear to your friends.", textFieldPlaceholder: "", textFieldText: user.screenName) { [weak self] (screenName) in
            
            // Save the new screen name to the cloud
            UserController.shared.update(user, screenName: screenName) { (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        self?.screenNameLabel.text = "Screen Name: \(screenName)"
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
    
    @IBAction func resetPasswordButtonTapped(_ sender: UIButton) {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Present an alert to have the user enter their current password first
        presentTextFieldAlert(title: "Enter Current Password", message: "First enter your current password before you can change it", textFieldPlaceholder: nil) { [weak self] (currentPassword) in
            
            // Try to log the user in with the entered password, to confirm their identity
            Auth.auth().signIn(withEmail: currentUser.email, password: currentPassword) { (authResult, error) in
                if let error = error {
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                    return
                }
                
                // Present a new alert allowing the user to enter a new password
                self?.presentTextFieldAlert(title: "Enter New Password", message: "Choose a new password", textFieldPlaceholder: nil, completion: { (newPassword) in
                    
                    // Update the password in the cloud
                    Auth.auth().currentUser?.updatePassword(to: newPassword, completion: { (error) in
                        if let error = error {
                            // Print and display the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            self?.presentErrorAlert(error)
                        }
                    })
                })
            }
        }
    }
    
    @IBAction func pointsInformationButtonTapped(_ sender: UIButton) {
        presentAlert(title: "Points", message: "Earn points by having your captions selected in games with your friends.")
    }
    
    @IBAction func signOutButtonTapped(_ sender: UIButton) {
        do {
            // Sign the user out and return to the main screen
            try Auth.auth().signOut()
            transitionToStoryboard(named: .Main)
        } catch let error {
            // Print and display the error
            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            presentErrorAlert(error)
        }
    }
    
    @IBAction func deleteAccountButtonTapped(_ sender: UIButton) {
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Present an alert to confirm deleting the account
        presentConfirmAlert(title: "Delete account?", message: "Are you sure you want to delete your account? This will permanently remove all your data from this device and from the cloud.") {
            
            // Show the loading icon
            self.view.startLoadingIcon()
            
            
            // If the user clicks confirm, delete their information from the cloud
            UserController.shared.deleteCurrentUser { [weak self] (result) in
                DispatchQueue.main.async {
                    self?.view.stopLoadingIcon()
                    
                    switch result {
                    case .success(_):
                        // Delete the user's account from the authorization side of Firebase
                        let user = Auth.auth().currentUser
                        user?.delete(completion: { (error) in
                            if let error = error {
                                // Print and display the error
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                self?.presentErrorAlert(error)
                            } else {
                                // Return to the login screen
                                self?.transitionToStoryboard(named: .Main)
                            }
                        })
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
}
