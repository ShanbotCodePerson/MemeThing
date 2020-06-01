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
        
        // Create the search predicate to look for all the user's friends
        // FIXME: - i don't think this predicate will work - check
        CKService.shared.read(referenceKey: UserStrings.appleUserReferenceKey, references: currentUser.friendsReferences) { [weak self] (result: Result<[User], MemeThingError>) in
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
        
        // Create the search predicate to look for all friend requests directed at the current user
        let predicate = NSPredicate(format: "%K == %@", argumentArray: [FriendRequestStrings.toKey, currentUser.username])
        // TODO: - limit to ones that have not been responded to yet
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate])
        
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
        
        // Create the search predicate to look for all friend requests sent from the current user
        let predicate = NSPredicate(format: "%K == %@", argumentArray: [FriendRequestStrings.fromKey, currentUser.username])
        // TODO: - limit to ones that have not been responded to yet
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate])
        
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
        
        // TODO: - check if a friend request already exists to or from that person
        
        // Create the friend request
        let friendRequest = FriendRequest(from: currentUser.username, to: user.username)
        
        // FIXME: - can't append to nil array
        
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
    
    func respond(to friendRequest: FriendRequest, accept: Bool, completion: @escaping resultHandler) {
        guard let currentUser = currentUser else { return completion(.failure(.noUserFound)) }
        
        // Change the status of the friend request
//        friendRequest.accepted = accept
        
        // Add the new friend to the list of friends, if applicable
//        // TODO: - get reference from username
//        if accept {
//            let friend = CKRecord.Reference //todo
//            currentUser?.friendsReferences.append(friend)
//            update(currentUser, friend: friend) { (result) in
//                // TODO: - how to handle multiple completions like this?
//            }
//        }
        
//        // Save the changes to the cloud
//        CKService.shared.update(object: friendRequest) { (result) in
//            // TODO: -
//        }
        
        // TODO: - need to remove friend request from source of truth and update display on view controller
        return completion(.success(true))
    }
    
    func subscribeToFriendRequests() {
        // TODO: - User defaults to track whether the subscription has already been saved
        guard let currentUser = currentUser else { return }
        
        // Form the predicate to look for friend requests directed at the current user
        // FIXME: - doesn't receive notifications with this predicate
        let predicate = NSPredicate(format: "%K == %@", argumentArray: [FriendRequestStrings.toKey, currentUser.username])
        let subscription = CKQuerySubscription(recordType: FriendRequestStrings.recordType, predicate: predicate, options: [.firesOnRecordCreation])
        
        // Format the display of the notification
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.title = "New Friend Request"
        notificationInfo.alertBody = "You have received a friend request on MemeThing"
        notificationInfo.shouldBadge = true
        subscription.notificationInfo = notificationInfo
        
        // Save the subscription to the cloud
        CKService.shared.publicDB.save(subscription) { (_, _) in }
    }
    
    func subscribeToFriendRequestResult() {
        // TODO: - if accepted, add to list of friends
        
        // TODO: - display an alert to the user with the result of the friend request
        
        // TODO: - delete the friend request from the cloud
        
        // TODO: - cause the tableview in the friends list to update automatically?
    }
}
