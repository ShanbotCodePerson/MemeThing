//
//  InviteFriendsTableViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/2/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class InviteFriendsTableViewController: UITableViewController {
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        tableView.backgroundColor = .lightGray
        
        // Load the data if it hasn't been loaded already
        if UserController.shared.usersFriends == nil {
            UserController.shared.fetchUsersFriends { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        self?.tableView.reloadData()
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorToUser(error)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions ?
    
    @IBAction func startGameButtonTapped(_ sender: UIButton) {
        // TODO: - check that enough players are selected
        
        // TODO: - create the game object, send the invitations, etch
        
        // Transition to the gameplay screen with the current user as the first lead player
        let storyboard = UIStoryboard(name: "Drawing", bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() else { return }
        initialVC.modalPresentationStyle = .fullScreen
        self.present(initialVC, animated: true)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserController.shared.usersFriends?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath)

        guard let friend = UserController.shared.usersFriends?[indexPath.row] else { return cell }
        cell.textLabel?.text = friend.screenName
        cell.detailTextLabel?.text = "Points: \(friend.points)"

        return cell
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
}
