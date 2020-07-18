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
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setUpObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpViews()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeObservers()
    }
    
    // MARK: - Set Up View
    
    func setUpViews() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        guard let user = UserController.shared.currentUser else { return }
        welcomeLabel.text = "Welcome, \(user.screenName)!"
    }
    
    @IBAction func tempFakeNotifications(_ sender: UIButton) {
        // Reload all the data as if a notification of any sort had been received (for testing on simulators) 
        UserController.shared.fetchUsersFriends { (_) in }
        FriendRequestController.shared.fetchPendingFriendRequests { (_) in }
        FriendRequestController.shared.fetchOutgoingFriendRequests { (_) in }
        GameController.shared.fetchCurrentGames { (_) in }
    }
}
