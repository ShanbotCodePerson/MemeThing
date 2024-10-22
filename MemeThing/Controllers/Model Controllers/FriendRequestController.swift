//
//  FriendRequestController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/2/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase

class FriendRequestController {
    
    // MARK: - Singleton
    
    static let shared = FriendRequestController()
    
    // MARK: - Source of Truth
    
    var pendingFriendRequests: [FriendRequest]?
    var outgoingFriendRequests: [FriendRequest]?
    
    // MARK: - Properties
    
    let db = Firestore.firestore()
    
    // MARK: - CRUD Methods
    
    // Create a new friend request
    func sendFriendRequest(to user: User, addingFriend: Bool = true, completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Create a new friend request
        let friendRequest = FriendRequest(fromID: currentUser.recordID, fromName: currentUser.screenName, toID: user.recordID, toName: user.screenName, status: (addingFriend ? .waiting : .removingFriend))
        
        // Save it to the cloud
        db.collection(FriendRequestStrings.recordType)
            .addDocument(data: friendRequest.asDictionary()) { [weak self] (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Add it to the source of truth (unless the request is to remove)
                if addingFriend {
                    if self?.outgoingFriendRequests?.uniqueAppend(friendRequest) == nil {
                        self?.outgoingFriendRequests = [friendRequest]
                    }
                }
                
                // Send a local notification to update the tableview
                NotificationCenter.default.post(Notification(name: .friendsUpdate))
                
                // Return the success
                return completion(.success(true))
        }
    }
    
    // Create a request to remove a friend
    func sendRequestToRemove(_ user: User, userBeingDeleted: Bool = false, completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Remove the friend from the user's list of friends
        currentUser.friendIDs.removeAll(where: { $0 == user.recordID })
        
        // Remove the friend from the source of truth
        UserController.shared.usersFriends?.removeAll(where: { $0 == user })
        
        // Don't try to save the changes to the user if this is part of deleting the user
        if userBeingDeleted {
            // Send the notification to the unfriended user
            sendFriendRequest(to: user, addingFriend: false, completion: completion)
            return
        }
        
        // Save the changes to the user
        UserController.shared.saveChanges(to: currentUser) { [weak self] (result) in
            switch result {
            case .success(_):
                // Send the notification to the unfriended user
                self?.sendFriendRequest(to: user, addingFriend: false, completion: completion)
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Read (fetch) all the pending friend requests
    func fetchPendingFriendRequests(completion: @escaping resultCompletionWith<Int>) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Fetch the data from the cloud
        db.collection(FriendRequestStrings.recordType)
            .whereField(FriendRequestStrings.toIDKey, isEqualTo: currentUser.recordID)
            .whereField(FriendRequestStrings.statusKey, isEqualTo: FriendRequest.Status.waiting.rawValue)
            .getDocuments { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                let pendingFriendRequests = documents.compactMap { (document) -> FriendRequest? in
                    guard let friendRequest = FriendRequest(dictionary: document.data()) else { return nil }
                    friendRequest.documentID = document.documentID
                    return friendRequest
                }
                
                // Save the data to the source of truth
                self?.pendingFriendRequests = pendingFriendRequests
                
                // TODO: - display alerts for each friend request?
                
                // Send a local notification to update the friends tableview
                NotificationCenter.default.post(Notification(name: .friendsUpdate))
                
                // Return the success
                return completion(.success(pendingFriendRequests.count))
        }
    }
    
    // Read (fetch) all the outgoing friend requests
    func fetchOutgoingFriendRequests(completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Fetch the data from the cloud
        db.collection(FriendRequestStrings.recordType)
            .whereField(FriendRequestStrings.fromIDKey, isEqualTo: currentUser.recordID)
            .whereField(FriendRequestStrings.statusKey, isEqualTo: FriendRequest.Status.waiting.rawValue)
            .getDocuments { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                let outgoingFriendRequests = documents.compactMap { (document) -> FriendRequest? in
                    guard let friendRequest = FriendRequest(dictionary: document.data()) else { return nil }
                    friendRequest.documentID = document.documentID
                    return friendRequest
                }
                
                // Save the data to the source of truth
                self?.outgoingFriendRequests = outgoingFriendRequests
                
                // TODO: - display alerts for each friend request?
                
                // Send a local notification to update the friends tableview
                NotificationCenter.default.post(Notification(name: .friendsUpdate))
                
                // Return the success
                return completion(.success(true))
        }
    }
    
    // Update a friend request with a response
    func respondToFriendRequest(_ friendRequest: FriendRequest, accept: Bool, completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        guard let documentID = friendRequest.documentID else { return completion(.failure(.noData)) }
        
        // Update the friend request
        friendRequest.status = accept ? .accepted : .denied
        
        // If the user accepted the friend request, add and save the friend
        if accept {
            currentUser.friendIDs.append(friendRequest.fromID)
            
            // Save the changes to the user
            UserController.shared.saveChanges(to: currentUser) { (result) in
                switch result {
                case .success(_):
                    // Update the source of truth
                    // TODO: - only fetch the one new friend, add it to the source of truth
                    UserController.shared.fetchUsersFriends { (result) in
                        switch result {
                        case .success(_):
                            // Send a local notification to update the friends tableview
                            NotificationCenter.default.post(Notification(name: .friendsUpdate))
                        case .failure(let error):
                            // Print and return the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            return completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            }
        }
        
        // Save the changes to the friend request
        db.collection(FriendRequestStrings.recordType)
            .document(documentID)
            .updateData([FriendRequestStrings.statusKey : friendRequest.status.rawValue]) { [weak self] (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Remove the friend request from the source of truth
                self?.pendingFriendRequests?.removeAll(where: { $0 == friendRequest })
                
                // Send a local notification to update the friends tableview
                NotificationCenter.default.post(Notification(name: .friendsUpdate))
                
                // Otherwise return the success
                return completion(.success(true))
        }
    }
    
    // Delete a friend request when it's no longer necessary
    func delete(_ friendRequest: FriendRequest, completion: @escaping resultCompletion) {
        guard let documentID = friendRequest.documentID else { return completion(.failure(.noData)) }
        
        // Delete the friend request from the cloud
        db.collection(FriendRequestStrings.recordType)
            .document(documentID)
            .delete() { (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                    // Otherwise return the success
                else { return completion(.success(true)) }
        }
    }
    
    // Delete friend requests associated with the current user
    func deleteAll(completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        let group = DispatchGroup()
        
        // Fetch all outstanding friend requests sent by the user
        group.enter()
        db.collection(FriendRequestStrings.recordType)
            .whereField(FriendRequestStrings.fromIDKey, isEqualTo: currentUser.recordID)
            .whereField(FriendRequestStrings.statusKey, isLessThan: FriendRequest.Status.removingFriend.rawValue)
            .getDocuments(completion: { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                
                // Delete all the voting invitations
                documents.forEach {
                    self?.db.collection(FriendRequestStrings.recordType).document($0.documentID).delete()
                }
                
                group.leave()
            })
        
        // Fetch all outstanding friend requests sent to the user
        group.enter()
        db.collection(FriendRequestStrings.recordType)
            .whereField(FriendRequestStrings.toIDKey, isEqualTo: currentUser.recordID)
            .getDocuments(completion: { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                
                // Delete all the voting invitations
                documents.forEach {
                    self?.db.collection(FriendRequestStrings.recordType).document($0.documentID).delete()
                }
                
                group.leave()
            })
        
        group.notify(queue: .main) { return completion(.success(true)) }
    }
    
    // MARK: - Notifications
    
    func subscribeToFriendRequestNotifications() {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Set up a listener to be alerted of any adding-type friend requests with the current user as the recipient
        db.collection(FriendRequestStrings.recordType)
            .whereField(FriendRequestStrings.toIDKey, isEqualTo: currentUser.recordID)
            .whereField(FriendRequestStrings.statusKey, isEqualTo: FriendRequest.Status.waiting.rawValue)
            .addSnapshotListener { [weak self] (snapshot, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
                
                // Unwrap the data
                guard let documents = snapshot?.documents else { return }
                let newFriendRequests = documents.compactMap { (document) -> FriendRequest? in
                    guard let friendRequest = FriendRequest(dictionary: document.data()) else { return nil }
                    friendRequest.documentID = document.documentID
                    return friendRequest
                }
                
                for friendRequest in newFriendRequests {
                    // Add the friend request to the source of truth if it isn't already
                    if self?.pendingFriendRequests?.uniqueAppend(friendRequest) == nil {
                        self?.pendingFriendRequests = [friendRequest]
                    }
                    
                    // Send a local notification to update the friends tableview
                    NotificationCenter.default.post(Notification(name: .friendsUpdate))
                    
                    // Create a notification to display if the user is looking at a different view
                    // FIXME: - check what view the user is currently on
                    NotificationHelper.createFriendRequestNotification(friendRequest)
                }
        }
    }
    
    func subscribeToFriendRequestResponseNotifications() {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Set up a listener to be alerted of changes to friend requests with the current user as the sender
        db.collection(FriendRequestStrings.recordType)
            .whereField(FriendRequestStrings.fromIDKey, isEqualTo: currentUser.recordID)
            .whereField(FriendRequestStrings.statusKey, in: [FriendRequest.Status.accepted.rawValue, FriendRequest.Status.denied.rawValue])
            .addSnapshotListener { [weak self] (snapshot, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
                
                // Unwrap the data
                guard let documents = snapshot?.documents else { return }
                let newResponses = documents.compactMap { (document) -> FriendRequest? in
                    guard let friendRequest = FriendRequest(dictionary: document.data()) else { return nil }
                    friendRequest.documentID = document.documentID
                    return friendRequest
                }
                let acceptedRequests = newResponses.filter({ $0.status == .accepted })
                
                // If the request was accepted, add the friends to the user's list of friends, avoiding duplicates
                currentUser.friendIDs.append(contentsOf: acceptedRequests.map({ $0.toID }))
                currentUser.friendIDs = Array(Set(currentUser.friendIDs))
                
                // Save the changes to the user
                UserController.shared.saveChanges(to: currentUser) { (result) in
                    switch result {
                    case .success(_):
                        for response in newResponses {
                            // Update the source of truth
                            // TODO: - more efficient way to do this rather than fetching all friends every time
                            UserController.shared.fetchUsersFriends { (result) in
                                switch result {
                                case .success(_):
                                    // Send a local notification to update the friends tableview
                                    NotificationCenter.default.post(Notification(name: .friendsUpdate))
                                case .failure(let error):
                                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                }
                            }
                            // Delete the requests from the cloud now that they're no longer necessary
                            self?.delete(response, completion: { (_) in })
                        }
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    }
                }
                
                // Remove the requests from the source of truth
                self?.outgoingFriendRequests?.removeAll(where: { newResponses.contains($0) })
                
                // Send a local notification to update the friends tableview
                NotificationCenter.default.post(Notification(name: .friendsUpdate))
                
                for friendRequest in newResponses {
                    // Create a notification to display if the user is looking at a different view
                    // FIXME: - check what view the user is currently on
                    NotificationHelper.createFriendResponseNotification(friendRequest)
                    
                    // Delete the request now that it's no longer needed
                    self?.delete(friendRequest, completion: { (_) in })
                }
        }
    }
    
    func subscribeToRemovingFriendNotifications() {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Set up a listener to be alerted of any removing-type friend requests with the current user as the recipient
        db.collection(FriendRequestStrings.recordType)
            .whereField(FriendRequestStrings.toIDKey, isEqualTo: currentUser.recordID)
            .whereField(FriendRequestStrings.statusKey, isEqualTo: FriendRequest.Status.removingFriend.rawValue)
            .addSnapshotListener { [weak self] (snapshot, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
                
                // Unwrap the data
                guard let documents = snapshot?.documents else { return }
                let friendsRemoving = documents.compactMap { (document) -> FriendRequest? in
                    guard let friendRequest = FriendRequest(dictionary: document.data()) else { return nil }
                    friendRequest.documentID = document.documentID
                    return friendRequest
                }
                let friendsIDs = friendsRemoving.compactMap { $0.fromID }
                
                // Remove the friends from the users list of friends
                currentUser.friendIDs.removeAll(where: { friendsIDs.contains($0) })
                
                // Save the changes to the user
                UserController.shared.saveChanges(to: currentUser) { (result) in
                    switch result {
                    case .success(_):
                        // Update the source of truth
                        UserController.shared.usersFriends?.removeAll(where: { friendsIDs.contains($0.recordID) })
                        
                        // Send a local notification to update the tableview
                        NotificationCenter.default.post(Notification(name: .friendsUpdate))
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    }
                }
                
                // Delete the requests from the cloud now that they're no longer necessary
                friendsRemoving.forEach({ self?.delete($0, completion: { (_) in }) })
        }
    }
}
