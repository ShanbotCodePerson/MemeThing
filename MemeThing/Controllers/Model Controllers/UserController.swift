//
//  UserController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit

class UserController {
    
    // MARK: - Singleton
    
    static let shared = UserController()
    
    // MARK: - Source of Truth
    
    var currentUser: User?
    var usersFriends: [User]?
    var pendingFriendRequests: [FriendRequest]?
    var outgoingFriendRequests: [FriendRequest]?
    
    // MARK: - Properties
    
    typealias resultHandler = (Result<Bool, MemeThingError>) -> Void
    
    // MARK: - CRUD Methods
    
    // Create a new user
    func createUser(with username: String, password: String, screenName: String?, email: String, completion: @escaping resultHandler) {
        // Get the apple user reference of the current user of the phone
        fetchAppleUserReference { [weak self] (reference) in
            guard let reference = reference else { return completion(.failure(.noUserFound))}
            
            // Create the new user
            let newUser = User(username: username, password: password, screenName: screenName, email: email, appleUserReference: reference)
            
            // Save the user to the cloud
            CKService.shared.create(object: newUser) { (result) in
                switch result {
                case .success(let user):
                    // Save the user to the source of truth
                    self?.currentUser = user
                    return completion(.success(true))
                case .failure(let error):
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            }
        }
    }
    
    // Read (fetch) the current user
    func fetchUser(completion: @escaping resultHandler) {
        // Get the apple user reference of the current user of the phone
        fetchAppleUserReference { [weak self] (reference) in
            guard let reference = reference else { return completion(.failure(.noUserFound))}
            
            // Create the search predicate to only look for the current user
            let predicate = NSPredicate(format: "%K == %@", argumentArray: [UserStrings.appleUserReferenceKey, reference])
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate])
            
            // Fetch the user from the cloud
            CKService.shared.read(predicate: compoundPredicate) { (result: Result<[User], MemeThingError>) in
                switch result {
                case .success(let users):
                    // There should only be one user
                    guard let user = users.first else { return completion(.failure(.noUserFound)) }
                    // Save the user to the source of truth and set up notifications for friend requests
                    self?.currentUser = user
                    self?.subscribeToFriendRequests()
                    return completion(.success(true))
                case .failure(let error):
                   // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            }
        }
    }
    
    // Read (fetch) all the friends of a user
    // TODO: - is this a problem with security? how to only have access to relevant details?
    func fetchUsersFriends(completion: @escaping resultHandler) {
        guard let currentUser = currentUser else { return completion(.failure(.noUserFound)) }
        
        // Return an empty array if the user has no friends
        // FIXME: - CHECK THIS
        if currentUser.friendsReferences.count == 0 {
            self.usersFriends = []
            return completion(.success(false))
        }
        
        let predicate = NSPredicate(format: "%K IN %@", argumentArray: ["recordID", currentUser.friendsReferences.compactMap({ $0.recordID })])
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate])
        print(compoundPredicate)
        
        // Create the search predicate to look for all the user's friends
        CKService.shared.read(predicate: compoundPredicate) { [weak self] (result: Result<[User], MemeThingError>) in
            switch result {
            case .success(let users):
                // Save the list of friends to the source of truth
                self?.usersFriends = users
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    func fetchPendingFriendRequests(completion: @escaping resultHandler) {
        guard let currentUser = currentUser else { return completion(.failure(.noUserFound)) }
        
        // Create the search predicate to look for all friend requests directed at the current user that have not yet been responded to
        let predicateToSelf = NSPredicate(format: "%K == %@", argumentArray: [FriendRequestStrings.toUsernameKey, currentUser.username])
        let predicateNoResponse = NSPredicate(format: "%K == %@", argumentArray: [FriendRequestStrings.statusKey, FriendRequest.Status.waiting.rawValue])
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateToSelf, predicateNoResponse])
        
        // Fetch the data from the cloud
        CKService.shared.read(predicate: compoundPredicate) { [weak self] (result: Result<[FriendRequest], MemeThingError>) in
            switch result {
            case .success(let friendRequests):
                // Save the list of friend requests to the source of truth
                self?.pendingFriendRequests = friendRequests
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    func fetchOutgoingFriendRequests(completion: @escaping resultHandler) {
        guard let currentUser = currentUser else { return completion(.failure(.noUserFound)) }
        
        // Create the search predicate to look for all friend requests sent from the current user that have not yet been responded to
        let predicateFromSelf = NSPredicate(format: "%K == %@", argumentArray: [FriendRequestStrings.fromUsernameKey, currentUser.username])
        let predicateNoResponse = NSPredicate(format: "%K == %@", argumentArray: [FriendRequestStrings.statusKey, FriendRequest.Status.waiting.rawValue])
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateFromSelf, predicateNoResponse])
        
        // Fetch the data from the cloud
        CKService.shared.read(predicate: compoundPredicate) { [weak self] (result: Result<[FriendRequest], MemeThingError>) in
            switch result {
            case .success(let friendRequests):
                // Save the list of friend requests to the source of truth
                self?.outgoingFriendRequests = friendRequests
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Read (fetch) a search for another user
    func searchFor(_ username: String, completion: @escaping (Result<User, MemeThingError>) -> Void) {
        // TODO: - allow searching based on screen name or based on partial username
        
        // Create the search predicate to only look for the given username
        let predicate = NSPredicate(format: "%K == %@", argumentArray: [UserStrings.usernameKey, username])
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate])
        
        // Fetch the user from the cloud
        CKService.shared.read(predicate: compoundPredicate) { (result: Result<[User], MemeThingError>) in
            switch result {
            case .success(let users):
                // There should only be one user with that username
                guard let user = users.first else { return completion(.failure(.noUserFound)) }
                // Return the result
                return completion(.success(user))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Update a user - generic helper function for other update functionality
    private func update(_ user: User, completion: @escaping resultHandler) {
        CKService.shared.update(object: user) { (result) in
            switch result {
            case .success(_):
                // Return the success
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Update a user with new profile information
    func update(_ user: User, password: String?, screenName: String?, email: String?, completion: @escaping resultHandler) {
        // Update any fields that changed
        if let password = password { user.password = password }
        if let screenName = screenName { user.screenName = screenName }
        if let email = email { user.email = email }
        
        // Save the changes to the cloud
        update(user, completion: completion)
    }
    
    // Update a user's points
    func update(_ user: User, points: Int, completion: @escaping resultHandler) {
        // Update the user's points
        user.points += points
        
        // Save the changes to the cloud
        update(user, completion: completion)
    }
    
    // Update a user with a new friend
    func update(_ user: User, friend: CKRecord.Reference, completion: @escaping resultHandler) {
        // Add the friend to the user's list of friends
        user.friendsReferences.append(friend)
        
        // Save the changes to the cloud
        update(user, completion: completion)
    }
    
    // Delete a user
    func delete(_ user: User, completion: @escaping resultHandler) {
        CKService.shared.delete(object: user) { (result) in
            switch result {
            case .success(_):
                // Return the success
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // MARK: - Helper Method
    
    // Get the apple user reference of the user from their phone
    func fetchAppleUserReference(completion: @escaping (CKRecord.Reference?) -> Void) {
        CKContainer.default().fetchUserRecordID { (recordID, error) in
            // Handle the error
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(nil)
            }
            
            // Unwrap the data
            guard let recordID = recordID else { return completion(nil) }
            let reference = CKRecord.Reference(recordID: recordID, action: .none)
            return completion(reference)
        }
}
    
    // MARK: - Notifications
    
    func sendFriendRequest(to user: User, completion: @escaping resultHandler) {
        guard let currentUser = currentUser else { return completion(.failure(.noUserFound)) }
        
        // Create the friend request
        let friendRequest = FriendRequest(fromReference: currentUser.reference, fromUsername: currentUser.username, toReference: user.reference, toUsername: user.username)
        
        // Save the friend request to the cloud
        CKService.shared.create(object: friendRequest) { (result) in
            switch result {
            case .success(_):
                // Return the success
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    func sendResponse(to friendRequest: FriendRequest, accept: Bool, completion: @escaping resultHandler) {
        guard let currentUser = currentUser else { return completion(.failure(.noUserFound)) }
        
        // Change the status of the friend request
        friendRequest.status = accept ? .accepted : .denied
        
        // Add the new friend to the list of friends, if applicable
        if accept {
            update(currentUser, friend: friendRequest.fromReference) { (result) in
                print("got here to \(#function) and \(result)")
                // TODO: - how to handle multiple completions like this?
            }
        }
        
        // Save the changes to the cloud
        CKService.shared.update(object: friendRequest) { [weak self] (result) in
            switch result {
            case .success(_):
                // Remove the friend request from the source of truth
                guard let index = self?.pendingFriendRequests?.firstIndex(of: friendRequest) else { return completion(.failure(.unknownError)) }
                self?.pendingFriendRequests?.remove(at: index)
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
        
        // TODO: - need to remove friend request from source of truth and update display on view controller
    }
    
    func receiveResponseToFriendRequest() {
        guard let currentUser = currentUser else { return }
        
        // First get the reference(s) to the requests sent by the current user that have been accepted or rejected
        let predicateFromSelf = NSPredicate(format: "%K == %@", argumentArray: [FriendRequestStrings.fromUsernameKey, currentUser.username])
        let predicateHasResponse = NSPredicate(format: "%K != %@", argumentArray: [FriendRequestStrings.statusKey, FriendRequest.Status.waiting.rawValue])
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateFromSelf, predicateHasResponse])
        
        // Fetch the data from the cloud
        CKService.shared.read(predicate: compoundPredicate) { [weak self] (result: Result<[FriendRequest], MemeThingError>) in
            switch result {
            case .success(let friendRequests):
                for friendRequest in friendRequests { self?.handleResponse(to: friendRequest) }
            case .failure(let error):
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
    }
    
    // A helper function to handle responses to friend requests
    private func handleResponse(to friendRequest: FriendRequest) {
        guard let currentUser = currentUser else { return }
        
        // If the friend accepted, add them to the user's list of friends
        if friendRequest.status == .accepted {
            currentUser.friendsReferences.append(friendRequest.toReference)
            
            // Update the source of truth with the new friend
            CKService.shared.read(reference: friendRequest.toReference) { [weak self] (result: Result<User, MemeThingError>) in
                switch result {
                case .success(let friend):
                    // Update the source of truth
                    self?.usersFriends?.append(friend)
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                }
            }
        }
        
        // TODO: - display an alert to the user with the result of the friend request?? How would I do that?
        
        // Delete the friend request from the cloud
        CKService.shared.delete(object: friendRequest) { [weak self] (result) in
            switch result {
            case .success(_):
                // Remove the friend request from the source of truth
                guard let index = self?.outgoingFriendRequests?.firstIndex(of: friendRequest) else { return }
                self?.outgoingFriendRequests?.remove(at: index)
            case .failure(let error):
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
        
        // TODO: - cause the tableview in the friends list to update automatically?
    }
    
    func subscribeToFriendRequests() {
        // TODO: - User defaults to track whether the subscription has already been saved
        guard let currentUser = currentUser else { return }
        
        // Form the predicate to look for friend requests directed at the current user
        let predicate = NSPredicate(format: "%K == %@", argumentArray: [FriendRequestStrings.toUsernameKey, currentUser.username])
        let subscription = CKQuerySubscription(recordType: FriendRequestStrings.recordType, predicate: predicate, options: [.firesOnRecordCreation])
        
        // Format the display of the notification
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.title = "New Friend Request"
        notificationInfo.alertBody = "You have received a friend request on MemeThing"
        notificationInfo.category = NotificationStrings.newFriendRequest.rawValue
//        notificationInfo.shouldBadge = true // TODO: - Not sure I like this behavior
        subscription.notificationInfo = notificationInfo
        
        // Save the subscription to the cloud
        CKService.shared.publicDB.save(subscription) { (_, _) in }
    }
    
    func subscribeToFriendRequestResponses() {
        // TODO: - User defaults to track whether the subscription has already been saved
        guard let currentUser = currentUser else { return }
        
        // Form the predicate to look for friend requests sent from the current user that have been responded to
        let predicateFromSelf = NSPredicate(format: "%K == %@", argumentArray: [FriendRequestStrings.fromUsernameKey, currentUser.username])
        let predicateNoResponse = NSPredicate(format: "%K != %@", argumentArray: [FriendRequestStrings.statusKey, FriendRequest.Status.waiting.rawValue])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateFromSelf, predicateNoResponse])
        let subscription = CKQuerySubscription(recordType: FriendRequestStrings.recordType, predicate: predicate, options: [.firesOnRecordCreation])
        
        // Format the display of the notification
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.title = "Response to Friend Request"
        notificationInfo.alertBody = "New response to friend request on MemeThing" // FIXME: - be able to change this based on status of friend request
        notificationInfo.category = NotificationStrings.friendRequestResponse.rawValue
//        notificationInfo.shouldBadge = true // TODO: - Not sure I like this behavior
        subscription.notificationInfo = notificationInfo
        
        // Save the subscription to the cloud
        CKService.shared.publicDB.save(subscription) { (_, _) in }
    }
}

enum NotificationStrings: String {
    case newFriendRequest = "NEW_FRIEND_REQUEST"
    case friendRequestResponse = "FRIEND_REQUEST_RESPONSE"
}
