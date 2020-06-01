//
//  FriendsListTableViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class FriendsListTableViewController: UITableViewController {
    
    // MARK: - Lifecycle Methods
    
    // TODO: - have a place to display pending friend requests
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: true)
        tableView.tableFooterView = UIView()
        
        // Load all the data, if it hasn't been loaded already
        loadAllData()
    }
    
    // MARK: - Helper Methods
    
    func loadAllData() {
        if UserController.shared.pendingFriendRequests == nil {
            UserController.shared.fetchPendingFriendRequests { (result) in
                // TODO: -
            }
        }
        if UserController.shared.outgoingFriendRequests == nil {
            UserController.shared.fetchOutgoingFriendRequests { (result) in
                // TODO: -
            }
        }
        if UserController.shared.usersFriends == nil {
            UserController.shared.fetchUsersFriends { (result) in
                // TODO: -
            }
        }
        sleep(1) // FIXME: - I know this isn't the right way to do it
        tableView.reloadData()
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
        
        // Make sure the user hasn't already sent a request to or received a request from that username
        if let outgoingFriendRequests = UserController.shared.outgoingFriendRequests {
            guard outgoingFriendRequests.filter({ $0.to == username }).count == 0 else {
                presentAlert(title: "Already Sent", message: "You have already sent a friend request to \(username)")
                return
            }
        }
        if let pendingFriendRequests = UserController.shared.pendingFriendRequests {
            guard pendingFriendRequests.filter({ $0.from == username }).count == 0 else {
                presentAlert(title: "Already Received", message: "You have already received a friend request from \(username)")
                return
            }
        }
        
        // Search to see if that username exists
        UserController.shared.searchFor(username) { [weak self] (result) in
            switch result {
            case .success(let friend):
                // If the username exists, send them a friend request
                UserController.shared.sendFriendRequest(to: friend) { (result) in // FIXME: - better way than nested functions?
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            self?.presentAlert(title: "Friend Request Sent", message: "A friend request has been sent to \(friend.username)")
                            // TODO: - update tableview?
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
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    // TODO: - hide sections if they're empty
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Pending friend requests"
        case 1:
            return "Sent friend requests"
        case 2:
            return "Current friends"
        default:
            // TODO: - better error handling here
            return "Error"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
             return UserController.shared.pendingFriendRequests?.count ?? 0
        case 1:
             return UserController.shared.outgoingFriendRequests?.count ?? 0
        case 2:
             return UserController.shared.usersFriends?.count ?? 0
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath) as? FriendTableViewCell else { return UITableViewCell() }
        cell.delegate = self
        
        switch indexPath.section {
        case 0:
            guard let friendRequest = UserController.shared.pendingFriendRequests?[indexPath.row] else { return cell }
            cell.setUpViews(section: 0, username: friendRequest.from)
//            cell.setUpViews(section: 0, username: "test")
        case 1:
            guard let friendRequest = UserController.shared.outgoingFriendRequests?[indexPath.row] else { return cell }
            cell.setUpViews(section: 1, username: friendRequest.to)
//            cell.setUpViews(section: 1, username: "test2")
        case 2:
            guard let friend = UserController.shared.usersFriends?[indexPath.row] else { return cell }
            cell.setUpViews(section: 2, username: friend.username, points: friend.points)
//            cell.setUpViews(section: 2, username: "test3", points: 3)
        default:
            print("Error in \(#function) : too many sections somehow")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Enable swipe-to-delete functionality only for friends, not friend requests
        if indexPath.section == 2 { return true }
        return false
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // TODO: - first present alert to confirm unfriending someone
            
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - TableViewCell Button Delegate

extension FriendsListTableViewController: FriendTableViewCellButtonDelegate {
    
    func friendRequestResponse(for cell: FriendTableViewCell, accepted: Bool) {
        // Get the reference to the friend request that was responded to
        guard let indexPath = tableView.indexPath(for: cell), indexPath.section == 0,
            let friendRequest = UserController.shared.pendingFriendRequests?[indexPath.row]
            else { return }
        
        // Respond to the friend request
        UserController.shared.respond(to: friendRequest, accept: accepted) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Show an alert that the friend request has been accepted or denied
                    if accepted {
                        self?.presentAlert(title: "Friend Added", message: "You have successfully added \(friendRequest.from) as a friend!")
                    }
                    // TODO: - if denied, give user opportunity to block that person?
                    // Refresh the tableview to reflect the changes
                    self?.tableView.reloadData()
                case .failure(let error):
                    // Otherwise, display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorToUser(error)
                }
            }
        }
    }
}
