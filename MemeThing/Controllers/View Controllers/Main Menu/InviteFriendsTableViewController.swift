//
//  InviteFriendsTableViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/2/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class InviteFriendsTableViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var startGameButton: UIButton!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Set up the UI
        setUpViews()
        
        // Load the data if it hasn't been loaded already
        loadData()
    }
    
    // MARK: - Helper Methods
    
    func setUpViews() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        tableView.register(UINib(nibName: "ThreeLabelsTableViewCell", bundle: nil), forCellReuseIdentifier: "friendCell")
        
        // Start off with the button disabled until enough players have been selected for the game
        startGameButton.deactivate()
    }
    
    func loadData() {
        if UserController.shared.usersFriends == nil {
            // Show the loading icon
            view.startLoadingIcon()
            
            UserController.shared.fetchUsersFriends { [weak self] (result) in
                DispatchQueue.main.async {
                    // Hide the loading icon
                    self?.view.stopLoadingIcon()
                    
                    switch result {
                    case .success(_):
                        self?.tableView.reloadData()
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func startGameButtonTapped(_ sender: UIButton) {
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Get the list of selected players
        guard let indexPaths = tableView.indexPathsForSelectedRows else { return }
        let friends = indexPaths.compactMap { UserController.shared.usersFriends?[$0.row] }
        
        // Show the loading icon
        view.startLoadingIcon()

        // Create the game object, thus saving it to the cloud and thus automatically alerting the selected players
        GameController.shared.newGame(players: friends) { [weak self] (result) in
            DispatchQueue.main.async {
                // Hide the loading icon
                self?.view.stopLoadingIcon()
                
                switch result {
                case .success(let game):
                    // Transition to the waiting view, passing along the reference to the current game
                    self?.transitionToStoryboard(named: .Waiting, with: game)
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(UserController.shared.usersFriends?.count ?? 0, 1)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath) as? ThreeLabelsTableViewCell else { return UITableViewCell() }
        
        // Fill in the details of the cell with the friend's information
        if let friends = UserController.shared.usersFriends, friends.count > 0 {
            let friend = friends[indexPath.row]
            cell.setUpUI(firstText: friend.screenName, secondText: "Points: \(friend.points)")
            cell.isUserInteractionEnabled = true
        }
            // Insert a filler row if the user has not added any friends yet
        else {
            cell.setUpUI(firstText: "You have not added any friends yet")
            cell.isUserInteractionEnabled = false
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Check how many rows are selected and enable or disable the start game button accordingly
        if let indexPaths = tableView.indexPathsForSelectedRows, indexPaths.count > 1 {
            startGameButton.activate()
        }
        else  { startGameButton.deactivate() }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // Check how many rows are selected and enable or disable the start game button accordingly
        if let indexPaths = tableView.indexPathsForSelectedRows, indexPaths.count > 1 {
            startGameButton.activate()
        }
        else { startGameButton.deactivate() }
    }
}
