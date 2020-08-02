//
//  ProfileViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var profilePhotoImageView: UIImageView!
    @IBOutlet weak var drawingProfilePhotoPopoverView: UIView!
    @IBOutlet weak var canvasView: CanvasView!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    
    // MARK: - Properties
    
    var imagePicker = UIImagePickerController()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpObservers()
        
        // Set up the observer to update the UI when the photo is done saving
        NotificationCenter.default.addObserver(self, selector: #selector(refreshUI), name: .updateProfileView, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeObservers()
    }
    
    // MARK: - Notifications
    
    @objc func refreshUI() {
        DispatchQueue.main.async { self.profilePhotoImageView.image = UserController.shared.currentUser?.photo }
    }
    
    // MARK: - Set Up Views
    
    func setUpViews() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        imagePicker.delegate = self
        
        guard let currentUser = UserController.shared.currentUser else { return }
        profilePhotoImageView.image = currentUser.photo
        screenNameLabel.text = "Screen Name: \(currentUser.screenName)"
        emailLabel.text = "Email: \(currentUser.email)"
        pointsLabel.text = "Points: \(currentUser.points)"
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor.cyan.cgColor, UIColor.blue.cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // MARK: - Actions
    
    @IBAction func editProfilePhotoButtonTapped(_ sender: UIButton) {
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Create an alert controller with options for how to get a photo
        let alertController = UIAlertController(title: "New Profile Photo!", message: nil, preferredStyle: .alert)
        
        // Add a button option for the photo library
        let photoLibraryAction = UIAlertAction(title: "Choose a photo from your library", style: .default) { [weak self] (_) in
            self?.openPhotoLibrary()
        }
        
        // Add a button option for the camera
        let cameraAction = UIAlertAction(title: "Take a photo with your camera", style: .default) { [weak self] (_) in
            self?.openCamera()
        }
        
        // Add a button option for drawing a sketch
        let drawAction = UIAlertAction(title: "Draw a sketch of yourself", style: .default) { [weak self] (_) in
            self?.drawingProfilePhotoPopoverView.isHidden = false
        }
        
        // Add a button for the user to dismiss the alert
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (_) in
            self?.imagePicker.dismiss(animated: true, completion: nil)
        }
        
        // Add the actions and present the alert
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cameraAction)
        alertController.addAction(drawAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    @IBAction func undoButtonTapped(_ sender: UIButton) {
        canvasView.undoDraw()
    }
    
    @IBAction func discardDrawingButtonTapped(_ sender: UIButton) {
        drawingProfilePhotoPopoverView.isHidden = true
    }
    
    @IBAction func saveDrawingButtonTapped(_ sender: UIButton) {
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Create the image from the canvas (hide the undo button first so that it isn't saved in the screenshot)
        undoButton.isHidden = true
        let image = canvasView.getImage()
        
        // Show the loading icon
        view.startLoadingIcon()
        
        // Save the profile photo
        UserController.shared.update(image) { [weak self] (result) in
            DispatchQueue.main.async {
                // Hide the loading icon
                self?.view.stopLoadingIcon()
                
                switch result {
                case .success(_):
                    // Update the photo and hide the drawing screen
                    self?.profilePhotoImageView.image = image
                    self?.drawingProfilePhotoPopoverView.isHidden = true
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                    self?.drawingProfilePhotoPopoverView.isHidden = true
                }
            }
        }
    }
    
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

// MARK: - Image Picker Delegate

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true)
        } else {
            presentAlert(title: "Camera Access Not Available", message: "Please allow access to your camera to use this feature")
        }
    }
    
    func openCamera() {
          if UIImagePickerController.isSourceTypeAvailable(.camera) {
              imagePicker.sourceType = .camera
              present(imagePicker, animated: true)
          } else {
            presentAlert(title: "Photo Library Access Not Available", message: "Please allow access to your photo library to use this feature")
          }
      }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Get the photo
        guard let photo = info[.originalImage] as? UIImage else { return }
        
        // Close the image picker
        imagePicker.dismiss(animated: true)
        
        // Save the photo to the cloud
        profilePhotoImageView.startLoadingIcon()
        UserController.shared.update(photo) { [weak self] (result) in
            DispatchQueue.main.async {
                self?.profilePhotoImageView.stopLoadingIcon()
                
                switch result {
                case .success(_):
                    // Update the UI
                    self?.profilePhotoImageView.image = photo
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
      
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true)
    }
}
