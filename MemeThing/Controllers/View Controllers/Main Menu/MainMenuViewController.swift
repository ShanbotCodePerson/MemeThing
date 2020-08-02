//
//  MainMenuViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class MainMenuViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var gamesBadgeImage: UIImageView!
    @IBOutlet weak var friendsBadgeImage: UIImageView!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Make sure that the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        setUpObservers()
        loadAllData()
        
        // Set up the observers to listen for notifications of game invitations or friend requests to update the badges
        NotificationCenter.default.addObserver(self, selector: #selector(refreshBadgeImages), name: .updateListOfGames, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshBadgeImages), name: .friendsUpdate, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpViews()
        
        // Set up the badges on the games and friends buttons
        refreshBadgeImages()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeObservers()
    }
    
    // MARK: - Notifications
    
    // TODO: - set up notifications to display badges when new games or friend requests come in
    @objc func refreshBadgeImages() {
        DispatchQueue.main.async {
            if let games = GameController.shared.currentGames { self.setUpGamesBadgeImage(for: games) }
            if let friendRequests = FriendRequestController.shared.pendingFriendRequests?.count { self.setUpFriendsBadgeImage(for: friendRequests) }
        }
    }
    
    // MARK: - Set Up View
    
    func setUpViews() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        guard let user = UserController.shared.currentUser else { return }
        welcomeLabel.text = "Welcome, \(user.screenName)!"
        
        //Beth added:
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor.cyan.cgColor, UIColor.blue.cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func loadAllData() {
        // Load all the game data
        if GameController.shared.currentGames == nil {
            GameController.shared.fetchCurrentGames { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let games):
                        // If there are new game invitations, show the badge on the games button
                        self?.setUpGamesBadgeImage(for: games)
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
        
        // Load all pending friend requests
        if FriendRequestController.shared.pendingFriendRequests == nil {
            FriendRequestController.shared.fetchPendingFriendRequests { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let newRequests):
                        self?.setUpFriendsBadgeImage(for: newRequests)
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
    
    // Helper functions to control the badge image
    func setUpGamesBadgeImage(for games: [Game]) {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        let gameInvites = games.filter({ $0.getStatus(of: currentUser) == .invited }).count
        if gameInvites > 0 && gameInvites <= 50 {
            gamesBadgeImage.image = UIImage(systemName: "\(gameInvites).circle.fill")
            gamesBadgeImage.isHidden = false
        } else if gameInvites > 50 {
            gamesBadgeImage.image = UIImage(systemName: "circle.fill")
            gamesBadgeImage.isHidden = false
        } else {
            gamesBadgeImage.isHidden = true
        }
    }
    
    func setUpFriendsBadgeImage(for friendRequests: Int) {
        if friendRequests > 0 && friendRequests <= 50 {
            friendsBadgeImage.image = UIImage(systemName: "\(friendRequests).circle.fill")
            friendsBadgeImage.isHidden = false
        } else if friendRequests > 50 {
            friendsBadgeImage.image = UIImage(systemName: "circle.fill")
            friendsBadgeImage.isHidden = false
        } else {
            friendsBadgeImage.isHidden = true
        }
    }
    
    @IBAction func tempFakeNotifications(_ sender: UIButton) {
        // Reload all the data as if a notification of any sort had been received (for testing on simulators) 
        UserController.shared.fetchUsersFriends { (_) in }
        FriendRequestController.shared.fetchPendingFriendRequests { (_) in }
        FriendRequestController.shared.fetchOutgoingFriendRequests { (_) in }
        GameController.shared.fetchCurrentGames { (_) in }
    }
}
