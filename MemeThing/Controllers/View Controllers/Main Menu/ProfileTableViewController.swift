//
//  ProfileTableViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class ProfileTableViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    
    // MARK: - Properties
    
    var editingPassword = false
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    // MARK: - Set Up Views
    
    func setUpViews() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        view.backgroundColor = .background
        
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
        guard let user = UserController.shared.currentUser else { return }
        
        // First present an alert asking the user to confirm their current password
    }
    
    @IBAction func pointsInformationButtonTapped(_ sender: UIButton) {
        presentAlert(title: "Points", message: "Earn points by having your captions selected in games with your friends.")
    }
    
    @IBAction func signOutButtonTapped(_ sender: UIButton) {
    }
    
    @IBAction func deleteAccountButtonTapped(_ sender: UIButton) {
    }
}
