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
        // TODO: - Allow the current user to sign in
        
        // TODO: - handle signing in with a different account or something?
        
        // TODO: - check that the username and email are unique
        
        // TODO: - check that the remaining text fields have valid information
        
        // TODO: - check that the passwords match
        
        // TODO: - create the new user and transition to the main menu
        
    }
    
    // MARK: - Helper Methods
    
    func fetchUser() {
        // TODO: - try to get the current user from the cloud, transition to main menu if successful
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
