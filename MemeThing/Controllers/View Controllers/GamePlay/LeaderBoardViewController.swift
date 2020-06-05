//
//  LeaderboardViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/5/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class LeaderboardViewController: UIViewController, HasAGameObject {
    
    // MARK: - Outlets
    
    @IBOutlet weak var gameStatusLabel: UILabel!
    @IBOutlet weak var playersTableView: UITableView!
    
    // MARK: - Properties
    
    var game: Game?
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
    }
    
    // MARK: - Actions
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}
