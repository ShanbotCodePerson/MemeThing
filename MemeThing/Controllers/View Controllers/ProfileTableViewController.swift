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
    

    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    // MARK: - Set Up Views
    
    func setUpViews() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        guard let user = UserController.shared.currentUser else { return }
        usernameLabel.text = "Username: \(user.username)"
        screenNameLabel.text = "Screen Name: \(user.screenName)"
        passwordLabel.text = "Password: \(user.password)"
        emailLabel.text = "Email: \(user.email)"
        pointsLabel.text = "Points: \(user.points)"
    }
    
    // MARK: - Actions
    
    @IBAction func editScreenNameButtonTapped(_ sender: UIButton) {
    }
    
    @IBAction func showPasswordButtonTapped(_ sender: UIButton) {
    }
    
    @IBAction func editEmailButtonTapped(_ sender: UIButton) {
    }
    
    @IBAction func pointsInformationButtonTapped(_ sender: UIButton) {
    }
}
