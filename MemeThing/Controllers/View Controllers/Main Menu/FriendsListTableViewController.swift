//
//  FriendsListTableViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class FriendsListTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    enum SectionNames: String {
        case pendingFriendRequests = "Pending Friend Requests"
        case outgoingFriendRequests = "Outgoing Friend Requests"
        case friends = "Friends"
    }
    
    var dataSource: [(name: SectionNames, data: [Any])] {
        var arrays = [(SectionNames, [Any])]()
        if let pendingFriendRequests = FriendRequestController.shared.pendingFriendRequests {
            if pendingFriendRequests.count > 0 {
                arrays.append((.pendingFriendRequests, pendingFriendRequests))
            }
        }
        if let outgoingFriendRequests = FriendRequestController.shared.outgoingFriendRequests {
            if outgoingFriendRequests.count > 0 {
                arrays.append((.outgoingFriendRequests, outgoingFriendRequests))
            }
        }
        if var userFriends = UserController.shared.usersFriends {
            userFriends = userFriends.sorted { $1.screenName > $0.screenName }
            arrays.append((.friends, userFriends))
        }
        return arrays
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Load all the data, if it hasn't been loaded already
        loadAllData()
        
        // Set up the observer to listen for notifications telling the view to reload its data
        NotificationCenter.default.addObserver(self, selector: #selector(updateData), name: friendsUpdate, object: nil)
    }
    
    // MARK: - Helper Methods
    
    @objc func updateData() {
        DispatchQueue.main.async { print("got here to \(#function)"); self.tableView.reloadData() }
    }
    
    func setUpViews() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .background
    }
    
    func loadAllData() {
        let group = DispatchGroup()
        
        if FriendRequestController.shared.pendingFriendRequests == nil {
            group.enter()
            FriendRequestController.shared.fetchPendingFriendRequests { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        print("Successfully fetched pending friend requests")
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
                group.leave()
            }
        }
        if FriendRequestController.shared.outgoingFriendRequests == nil {
            group.enter()
            FriendRequestController.shared.fetchOutgoingFriendRequests { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        print("Successfully fetched outgoing friend requests")
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
                group.leave()
            }
        }
        if UserController.shared.usersFriends == nil {
            group.enter()
            UserController.shared.fetchUsersFriends { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        print("Successfully fetched current friends")
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.tableView.reloadData()
        }
    }
    
    func blockUser(named username: String) {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Add the username to the current user's list of blocked people and save the change to the cloud
        UserController.shared.update(currentUser, usernameToBlock: username) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self?.presentAlert(title: "Successfully Blocked", message: "You have successfully blocked \(username)")
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        presentTextFieldAlert(title: "Add Friend", message: "Send a friend request to a username", textFieldPlaceholder: "Enter username here...", saveButtonTitle: "Send Friend Request", completion: sendRequest(to:))
    }
    
    // A helper function for when the user clicks to add the friend
    func sendRequest(to username: String) {
        guard let currentUser = UserController.shared.currentUser,
            username != currentUser.username else {
                presentAlert(title: "Invalid Username", message: "You can't send a friend request to yourself")
                return
        }
        
        // Make sure the user hasn't already blocked, sent, received, or accepted a request from that username
        if currentUser.blockedUsernames.contains(username) {
            presentAlert(title: "Blocked", message: "You have blocked \(username)")
            return
        }
        if let outgoingFriendRequests = FriendRequestController.shared.outgoingFriendRequests {
            guard outgoingFriendRequests.filter({ $0.toUsername == username }).count == 0 else {
                presentAlert(title: "Already Sent", message: "You have already sent a friend request to \(username)")
                return
            }
        }
        if let pendingFriendRequests = FriendRequestController.shared.pendingFriendRequests {
            guard pendingFriendRequests.filter({ $0.fromUsername == username }).count == 0 else {
                presentAlert(title: "Already Received", message: "You have already received a friend request from \(username)")
                return
            }
        }
        if let userFriends = UserController.shared.usersFriends {
            guard userFriends.filter({ $0.username == username }).count == 0 else {
                presentAlert(title: "Already Friends", message: "You are already friends with \(username)")
                return
            }
        }
        
        // Search to see if that username exists
        UserController.shared.searchFor(username) { [weak self] (result) in
            switch result {
            case .success(let friend):
                // If the username exists, first make sure that the current user hasn't been blocked by that person
                guard !friend.blockedUsernames.contains(currentUser.username) else {
                    DispatchQueue.main.async {
                        self?.presentAlert(title: "Blocked", message: "You have been blocked by \(username)")
                    }
                    return
                }
                
                // Send them a friend request
                FriendRequestController.shared.sendFriendRequest(to: friend) { (result) in // FIXME: - better way than nested functions?
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            self?.presentAlert(title: "Friend Request Sent", message: "A friend request has been sent to \(friend.username)")
                            self?.tableView.reloadData()
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
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource[section].name.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Add a placeholder row if the user has no friends
        if dataSource[section].name == .friends && dataSource[section].data.count == 0 { return 1 }
        return dataSource[section].data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath) as? FriendTableViewCell else { return UITableViewCell() }
        cell.delegate = self
        
        let sectionName = dataSource[indexPath.section].name
        let data = dataSource[indexPath.section].data
        
        switch sectionName {
        case .pendingFriendRequests:
            guard let friendRequest = data[indexPath.row] as? FriendRequest else { return cell }
            cell.setUpViews(section: sectionName, username: friendRequest.fromUsername)
        case .outgoingFriendRequests:
            guard let friendRequest = data[indexPath.row] as? FriendRequest else { return cell }
            cell.setUpViews(section: sectionName, username: friendRequest.toUsername)
        case .friends:
            // Add a placeholder row if the user has no friends
            if data.count == 0 { cell.setUpViews(section: sectionName, username: nil) }
            else {
                guard let friend = data[indexPath.row] as? User else { return cell }
                cell.setUpViews(section: sectionName, username: friend.screenName, points: friend.points)
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if dataSource[indexPath.section].name == .friends { return 50 }
        return 60
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Enable swipe-to-delete functionality only for friends, not friend requests
        if dataSource[indexPath.section].name == .friends && dataSource[indexPath.section].data.count > 0 { return true }
        return false
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Get the reference to the friend
            guard let friend = dataSource[indexPath.section].data[indexPath.row] as? User else { return }
            
            // Present an alert to confirm the user really wants to remove the friend
            presentConfirmAlert(title: "Are you sure?", message: "Are you sure you want to unfriend \(friend.screenName)?") {
                
                // Don't allow the user to interact with the view while the change is being processed
                tableView.isUserInteractionEnabled = false // TODO: - this needs to be tested, if it works, need to use in gameplay screens too
                
                // If the user clicks "confirm," remove the friend and update the tableview
                FriendRequestController.shared.remove(friend: friend) { [weak self] (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            // Give the user an opportunity to block the unwanted friend request
                            self?.presentConfirmAlert(title: "Friend Removed", message: "Do you want to block \(friend.username) from sending you any more friend requests?", completion: {
                                // If the user clicks "confirm," add that user to their blocked list
                                self?.blockUser(named: friend.username)
                            })
                            
                            // Update the tableview
                            self?.updateData()
                        case .failure(let error):
                            // Print and present the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            self?.presentErrorAlert(error)
                        }
                        // Turn user interaction back on
                        self?.tableView.isUserInteractionEnabled = true
                    }
                }
            }
        }
    }
}

// MARK: - TableViewCell Button Delegate

extension FriendsListTableViewController: FriendTableViewCellButtonDelegate {
    
    func respondToFriendRequest(from cell: FriendTableViewCell, accept: Bool) {
        // Get the reference to the friend request that was responded to
        guard let indexPath = tableView.indexPath(for: cell),
            dataSource[indexPath.section].name == .pendingFriendRequests,
            let friendRequest = dataSource[indexPath.section].data[indexPath.row] as? FriendRequest
            else { return }
        
        // Respond to the friend request
        FriendRequestController.shared.sendResponse(to: friendRequest, accept: accept) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Show an alert that the friend request has been accepted
                    if accept {
                        self?.presentAlert(title: "Friend Added", message: "You have successfully added \(friendRequest.fromUsername) as a friend!")
                    } else {
                        // Give the user an opportunity to block the unwanted friend request
                        self?.presentConfirmAlert(title: "Friend Request Denied", message: "Do you want to block \(friendRequest.fromUsername) from sending you any more friend requests?", completion: {
                            // If the user clicks "confirm," add that user to their blocked list
                            self?.blockUser(named: friendRequest.fromUsername)
                        })
                    }
                    
                    // Refresh the tableview to reflect the changes
                    self?.tableView.reloadData()
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
}
