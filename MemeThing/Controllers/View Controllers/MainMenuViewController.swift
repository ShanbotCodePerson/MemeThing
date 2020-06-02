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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(true, animated: true)
        setUpViews()
    }
    
    // MARK: - Set Up View
    
    func setUpViews() {
        guard let user = UserController.shared.currentUser else { return }
        welcomeLabel.text = "Welcome, \(user.screenName)!"
    }
}
