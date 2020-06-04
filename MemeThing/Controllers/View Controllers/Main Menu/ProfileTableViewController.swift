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
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var passwordButton: UIButton!
    
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
        tableView.backgroundColor = .lightGray
        
        guard let user = UserController.shared.currentUser else { return }
        usernameLabel.text = "Username: \(user.username)"
        screenNameLabel.text = "Screen Name: \(user.screenName)"
        passwordLabel.text = "Password: \(repeatElement("*", count: user.password.count).joined())"
        emailLabel.text = "Email: \(user.email)"
        pointsLabel.text = "Points: \(user.points)"
    }
    
    // MARK: - Actions
    
    @IBAction func editScreenNameButtonTapped(_ sender: UIButton) {
        guard let user = UserController.shared.currentUser else { return }
        
        presentTextFieldAlert(title: "Edit Screen Name", message: "Edit your name as it will appear to your friends.", textFieldPlaceholder: "", textFieldText: user.screenName) { [weak self] (screenName) in
            
            UserController.shared.update(user, password: nil, screenName: screenName, email: nil) { (result) in
                // TODO: - better handling of error and responses
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        self?.screenNameLabel.text = "Screen Name: \(screenName)"
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorToUser(error)
                    }
                }
            }
        }
    }
    
    @IBAction func showPasswordButtonTapped(_ sender: UIButton) {
        guard let user = UserController.shared.currentUser else { return }
        
        // Either allow the user to hide the password or show it
        if editingPassword {
            // TODO: - need to decide if I even want to do this
            passwordLabel.text = "Password: \(repeatElement("*", count: user.password.count).joined())"
            passwordButton.setTitle("Show", for: .normal)
            editingPassword = false
        } else {
            // Show the password and update the text of the button
            passwordLabel.text = "Password: \(user.password)"
            passwordButton.setTitle("Hide", for: .normal)
            editingPassword = true
        }
    }
    
    @IBAction func editEmailButtonTapped(_ sender: UIButton) {
        guard let user = UserController.shared.currentUser else { return }
        
        presentTextFieldAlert(title: "Edit Email", message: "Edit your email (used for password recovery)", textFieldPlaceholder: "", textFieldText: user.email) { [weak self] (email) in
            
            UserController.shared.update(user, password: nil, screenName: nil, email: email) { (result) in
                // TODO: - better handling of error and responses
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        self?.emailLabel.text = "Email: \(email)"
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorToUser(error)
                    }
                }
            }
        }
    }
    
    @IBAction func pointsInformationButtonTapped(_ sender: UIButton) {
        presentAlert(title: "Points", message: "Earn points by having your captions selected in games with your friends.")
    }
}