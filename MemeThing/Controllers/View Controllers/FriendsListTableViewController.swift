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
        
        // TODO: - show lists of all pending sent and received friend requests as well
    }
    
    // MARK: - Actions
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        presentTextFieldAlert(title: "Add Friend", message: "Send a friend request to a username", textFieldPlaceholder: "Enter username here...", saveButtonTitle: "Send Friend Request", completion: sendRequest(to:))
    }
    
    // A helper function for when the user clicks to add the friend
    func sendRequest(to username: String) {
        guard username != UserController.shared.currentUser?.username else {
            presentAlert(title: "Invalid Username", message: "You can't send a friend request to yourself")
            return
        }
        
        // Search to see if that username exists
        UserController.shared.searchFor(username) { [weak self] (result) in
            switch result {
            case .success(let friend):
                // If the username exists, create the notification to send them a friend request
                UserController.shared.sendFriendRequest(to: friend) { (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            self?.presentAlert(title: "Friend Request Sent", message: "A friend request has been sent to \(friend.username)")
                        case .failure(let error):
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            self?.presentAlert(title: "Uh-oh", message: "something went wrong - this shouldn't happen") // TODO: - replace with proper error message
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    // Otherwise, show an alert to the user that the username doesn't exist
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentAlert(title: "Username Not Found", message: "That username does not exist - make sure to enter the username carefully.")
                }
            }
        }
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
