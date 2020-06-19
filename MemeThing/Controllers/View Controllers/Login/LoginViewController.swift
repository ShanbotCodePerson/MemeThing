//
//  LoginViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var signUpToggleButton: UIButton!
    @IBOutlet weak var loginToggleButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var screenNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var textFieldsStackView: UIStackView!
    @IBOutlet weak var stackViewHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var keyboardHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var loadingIndictor: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    var signingUp = true
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make sure that the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Try to automatically log the user in using their cloud information
        fetchUser()
        
        // Set up the UI
        setUpViews()
        
        // Add an observer for when the keyboard appears or disappears
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
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
        
        // Either sign up or login
        if signingUp { signUp() }
        else { login() }
    }
    
    @IBAction func tappedScreen(_ sender: UITapGestureRecognizer) {
        // Close the keyboard for each text field
        usernameTextField.resignFirstResponder()
        screenNameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        confirmPasswordTextField.resignFirstResponder()
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        view.backgroundColor = .background
        // TODO: - need to test this in other device sizes
        stackViewHeightLayoutConstraint.constant = buttonsStackView.frame.height + textFieldsStackView.frame.height + 20
        loadingIndictor.isHidden = true
        
        usernameTextField.delegate = self
        screenNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
    }
    
    // Move the text fields out of the way if the keyboard is going to block them
    @objc func keyboardNotification(_ sender: NSNotification) {
        guard let userInfo = sender.userInfo else { return }
        
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let endFrameY = endFrame?.origin.y ?? 0
        let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
        if endFrameY >= UIScreen.main.bounds.size.height {
            self.keyboardHeightLayoutConstraint?.constant = 0.0
        } else {
            if let endFrame = endFrame {
                // Calculate the correct height to shift the text fields up by
                let currentHeight = (view.frame.height - stackViewHeightLayoutConstraint.constant) / 2
                self.keyboardHeightLayoutConstraint?.constant = -1 * (endFrame.size.height - currentHeight + 10)
            }
        }
        
        UIView.animate(withDuration: duration, delay: TimeInterval(0), options: animationCurve, animations: { self.view.layoutIfNeeded() }, completion: nil)
    }
    
    func toggleToLogin() {
        UIView.animate(withDuration: 0.2) {
            // Toggle which of the buttons is highlighted
            self.loginToggleButton.tintColor = .purpleAccent
            self.loginToggleButton.backgroundColor = .systemGray4
            self.signUpToggleButton.tintColor = .lightGray
            self.signUpToggleButton.backgroundColor = .clear
            
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
            self.loginToggleButton.tintColor = .lightGray
            self.loginToggleButton.backgroundColor = .clear
            self.signUpToggleButton.tintColor = .purpleAccent
            self.signUpToggleButton.backgroundColor = .systemGray4
            
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
    
    // Helper methods to disable the UI while the data is loading and reenable it when it's finished
    func disableUI() {
        loadingIndictor.startAnimating()
        loadingIndictor.isHidden = false
        
        signUpToggleButton.isUserInteractionEnabled = false
        loginToggleButton.isUserInteractionEnabled = false
        
        usernameTextField.isUserInteractionEnabled = false
        screenNameTextField.isUserInteractionEnabled = false
        emailTextField.isUserInteractionEnabled = false
        passwordTextField.isUserInteractionEnabled = false
        confirmPasswordTextField.isUserInteractionEnabled = false
        
        doneButton.deactivate()
    }
    
    func enableUI() {
        signUpToggleButton.isUserInteractionEnabled = true
        loginToggleButton.isUserInteractionEnabled = true
        
        usernameTextField.isUserInteractionEnabled = true
        screenNameTextField.isUserInteractionEnabled = true
        emailTextField.isUserInteractionEnabled = true
        passwordTextField.isUserInteractionEnabled = true
        confirmPasswordTextField.isUserInteractionEnabled = true
        
        doneButton.activate()
        
        loadingIndictor.stopAnimating()
        loadingIndictor.isHidden = true
    }
    
    // MARK: - Helper Methods
    
    // Try to get the current user from their iCloud information
    func fetchUser() {
        // Don't allow the user to interact with the screen while the data is loading
        disableUI()
        
        UserController.shared.fetchUser { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Go straight to the main menu if the user was fetched correctly
                    self?.presentMainMenuVC()
                case .failure(let error):
                    // Allow the user to interact with the UI again
                    self?.enableUI()
                    
                    // Print and display the error (unless the error is that no user has been created yet)
                    if case MemeThingError.noUserFound = error { return }
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    // Transition to the main menu
    func presentMainMenuVC() {
        DispatchQueue.main.async {
            self.transitionToStoryboard(named: StoryboardNames.mainMenu, direction: .fromRight)
        }
    }
    
    // Check that all the fields are valid and create a new user
    func signUp() {
        // Make sure the username contains an actual string
        guard let username = usernameTextField.text, !username.isEmpty else {
            presentAlert(title: "Invalid Username", message: "You must choose a username")
            return
        }
        
        // Don't allow the user to interact with the screen while the data is processing
        disableUI()
        
        // Check to see if the username is unique
        UserController.shared.searchFor(username) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                   // If the username is taken, present an alert
                    self?.presentAlert(title: "Username Taken", message: "That username is already taken - please choose a different username")
                    self?.enableUI()
                    return
                case .failure(let error):
                    // Make sure the error is that no user was found, rather than some other type of error
                    guard case MemeThingError.noUserFound = error else {
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                        self?.enableUI()
                        return
                    }
                    
                    // Make sure that the email is a valid email address
                    guard let email = self?.emailTextField.text, !email.isEmpty, email.isValidEmail()
                        else {
                            self?.presentAlert(title: "Invalid Email", message: "You must enter a valid email address to use for password recovery")
                            self?.enableUI()
                            return
                    }
                    
                    // Make sure that the remaining text fields have valid information
                    guard let screenName = self?.screenNameTextField.text,
                        let password = self?.passwordTextField.text, !password.isEmpty,
                        let confirmPassword = self?.confirmPasswordTextField.text
                        else {
                            self?.presentAlert(title: "Invalid Password", message: "You must enter a password")
                            self?.enableUI()
                            return
                    }
                    
                    // Make sure that the passwords match
                    guard let signingUp = self?.signingUp else { return }
                    if signingUp && password != confirmPassword {
                        self?.presentAlert(title: "Passwords Don't Match", message: "The passwords you have entered don't match - make sure to enter your password carefully")
                        self?.enableUI()
                        return
                    }
                    
                    // Create the new user
                    UserController.shared.createUser(with: username, password: password, screenName: screenName, email: email) { (result) in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(_):
                                // Go straight to the main menu if the user was created correctly
                                self?.presentMainMenuVC()
                            case .failure(let error):
                                // Print and return the error and allow the user to interact with the UI again
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                self?.presentErrorAlert(error)
                                self?.enableUI()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Check that the username and password are valid and fetch the user
    func login() {
        // Make sure the username contains an actual string
        guard let username = usernameTextField.text, !username.isEmpty else {
            presentAlert(title: "Username Missing", message: "You must enter a username")
            return
        }
        // Make sure that the password contains an actual string
        guard let password = passwordTextField.text, !password.isEmpty else {
            presentAlert(title: "Password Missing", message: "You must enter a password")
            return
        }
        
        // Don't allow the user to interact with the screen while the data is processing
        disableUI()
        
        // Check to see if the username is unique
        UserController.shared.searchFor(username) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    // Make sure that the password is correct
                    guard password == user.password else {
                        self?.presentAlert(title: "Incorrect Password", message: "The password you have entered does not match that username - please try again")
                        self?.enableUI()
                        return
                    }
                    
                    // Save the user to the source of truth and proceed to the main menu
                    UserController.shared.currentUser = user
                    self?.presentMainMenuVC()
                case .failure(let error):
                    // Display an alert if that username doesn't exist
                    if case MemeThingError.noUserFound = error {
                        self?.presentAlert(title: "Incorrect Username", message: "The username you have entered does not exist")
                    } else {
                        // Otherwise, print and return the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                    // Allow the user to interact with the UI again
                    self?.enableUI()
                }
            }
        }
    }
    
    // MARK: - Text Field Controls
    
    // TODO: - make "return" of last text field say "sign up" or "login" as appropriate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if signingUp {
            if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
                // If there's another text field, move the editing view to that text field
                nextField.becomeFirstResponder()
            } else {
                // Otherwise, remove the keyboard
                textField.resignFirstResponder()
            }
        }
            // Increment different in the login view where there are fewer text fields
        else {
            if let nextField = textField.superview?.viewWithTag(textField.tag + 3) as? UITextField {
                nextField.becomeFirstResponder()
            } else {
                // Otherwise, remove the keyboard
                textField.resignFirstResponder()
            }
        }
        
        return true
    }
}
