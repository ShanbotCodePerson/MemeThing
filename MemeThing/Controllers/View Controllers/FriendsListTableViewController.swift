//
//  FriendsListTableViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class FriendsListTableViewController: UITableViewController {
    
    // TODO: - have a place to display pending friend requests
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Load the user's friends, if they haven't been loaded already
        if UserController.shared.usersFriends == nil {
            UserController.shared.fetchUsersFriends { [weak self] (result) in
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
    
    // MARK: - Actions
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        presentAddFriendAlert()
    }
    
    // MARK: - Table view data source
    
    // TODO: - sort alphabetically, like contacts?
    //    override func numberOfSections(in tableView: UITableView) -> Int {
    //        return 0
    //    }
    
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // TODO: - first present alert to confirm unfriending someone
            
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - Alert Controller to Add Friend

extension FriendsListTableViewController {
    
    // Create and present the alert controller
    func presentAddFriendAlert() {
        // Create the alert controller
        let alertController = UIAlertController(title: "Add Friend", message: "Send a friend request by searching by username", preferredStyle: .alert)
        
        // Add the text field to enter a username
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter username here..."
        }
        
        // Create the cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Create the send button
        let sendAction = UIAlertAction(title: "Send Friend Request", style: .default) { [weak self] (_) in
            // Get the text from the text field
            guard let username = alertController.textFields?.first?.text, !username.isEmpty else { return }
            
            // Pass it to the helper function to handle sending the friend request
            self?.addFriend(with: username)
        }
        
        // Add the buttons to the alert controller and present it
        alertController.addAction(cancelAction)
        alertController.addAction(sendAction)
        present(alertController, animated: true)
    }
    
    // A helper function for when the user clicks to add the friend
    func addFriend(with username: String) {
        // Search to see if that username exists
        UserController.shared.searchFor(username) { [weak self] (result) in
            switch result {
            case .success(let friend):
                // If the username exists, create the notification to send them a friend request
                print(friend.username)
            case .failure(let error):
                // Otherwise, show an alert to the user that the username doesn't exist
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                self?.presentAlert(title: "Username Not Found", message: "That username does not exist - make sure to enter the username carefully.")
            }
        }
    }
}
