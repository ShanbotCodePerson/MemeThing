//
//  LoginViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var signUpToggleButton: UIButton!
    @IBOutlet weak var loginToggleButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var screenNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
    // MARK: - Properties
    
    var signingUp = true
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUser()
    }
    
    // MARK: - Actions
    
    @IBAction func signUpToggleButtonTapped(_ sender: UIButton) {
        toggleToSignUp()
    }
    
    @IBAction func loginToggleButtonTapped(_ sender: UIButton) {
        toggleToLogin()
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        // If the user has already logged in, don't create a new account but go straight to the main menu
        if UserController.shared.currentUser != nil {
            presentMainMenuVC()
            return
        }
        
        // TODO: - handle signing in with a different account or something?
        
        // Check to see if the username contains an actual string
        guard let username = usernameTextField.text, !username.isEmpty else {
            presentAlert(title: "Invalid Username", message: "You must choose a username")
            return
        }
        // Check to see if the username is unique
        UserController.shared.searchFor(username) { [weak self] (result) in
            switch result {
            case .success(_):
                // FIXME: - only run other code after checking that username is unique
                DispatchQueue.main.async { self?.presentAlert(title: "Username Taken", message: "That username is already taken - please choose a different username") }
                return
            case .failure(let error):
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
        
        // TODO: - check that the email is unique and is a valid email address
        
        // Check that the remaining text fields have valid information
        guard let screenName = screenNameTextField.text,
            let email = emailTextField.text,
            let password = passwordTextField.text, !password.isEmpty
            else {
                presentAlert(title: "Invalid Password", message: "You must enter a password")
                return
        }
        
        // Check that the passwords match
        if signingUp && password != confirmPasswordTextField.text {
            presentAlert(title: "Passwords Don't Match", message: "The passwords you have entered don't match - make sure to enter your password carefully")
            return
        }
        
        // Create the new user
        UserController.shared.createUser(with: username, password: password, screenName: screenName, email: email) { [weak self] (result) in
            switch result {
            case .success(_):
                // Go straight to the main menu if the user was created correctly
                self?.presentMainMenuVC()
            case .failure(let error):
                // TODO: - better error handling, error alert
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func fetchUser() {
        UserController.shared.fetchUser { [weak self] (result) in
            switch result {
            case .success(_):
                // Go straight to the main menu if the user was fetched correctly
                self?.presentMainMenuVC()
            case .failure(let error):
                // TODO: - better error handling, error alert
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
    }
    
    func toggleToLogin() {
        UIView.animate(withDuration: 0.2) {
            // Toggle which of the buttons is highlighted
            self.loginToggleButton.tintColor = .lightGray
            self.signUpToggleButton.tintColor = .systemBlue
            
            // Hide all but the necessary text fields
            self.screenNameTextField.isHidden = true
            self.emailTextField.isHidden = true
            self.confirmPasswordTextField.isHidden = true
            self.passwordTextField.returnKeyType = .done
            
            // Change the text of the done button
            self.doneButton.setTitle("Log In", for: .normal)
        }
        signingUp = false
    }
    
    func toggleToSignUp() {
        UIView.animate(withDuration: 0.2) {
            // Toggle which of the buttons is highlighted
            self.loginToggleButton.tintColor = .systemBlue
            self.signUpToggleButton.tintColor = .lightGray
            
            // Show all the text fields
            self.screenNameTextField.isHidden = false
            self.emailTextField.isHidden = false
            self.confirmPasswordTextField.isHidden = false
            self.passwordTextField.returnKeyType = .next
            
            // Change the text of the done button
            self.doneButton.setTitle("Sign Up", for: .normal)
        }
        signingUp = true
    }
    
    func presentMainMenuVC() {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "MainMenu", bundle: nil)
            guard let initialVC = storyboard.instantiateInitialViewController() else { return }
            initialVC.modalPresentationStyle = .fullScreen
            self.present(initialVC, animated: true)
        }
    }
}
