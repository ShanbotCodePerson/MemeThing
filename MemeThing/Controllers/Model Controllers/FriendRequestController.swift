//
//  FriendRequestController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/2/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit

class FriendRequestController {
    
    // MARK: - Singleton
    
    static let shared = FriendRequestController()
    
    // MARK: - Source of Truth
    
    var pendingFriendRequests: [FriendRequest]?
    var outgoingFriendRequests: [FriendRequest]?
    
    // MARK: - Properties
    
    typealias resultHandler = (Result<Bool, MemeThingError>) -> Void
    
    // MARK: - CRUD Methods
    
    // Read (fetch) all the pending friend requests
    func fetchPendingFriendRequests(completion: @escaping resultHandler) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
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
    
    // Read (fetch) all the outgoing friend requests
    func fetchOutgoingFriendRequests(completion: @escaping resultHandler) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
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
    
    // MARK: - Subscribe to Notifications
    
    func subscribeToFriendRequests() {
        // TODO: - User defaults to track whether the subscription has already been saved
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Form the predicate to look for friend requests directed at the current user
        let predicate = NSPredicate(format: "%K == %@", argumentArray: [FriendRequestStrings.toUsernameKey, currentUser.username])
        let subscription = CKQuerySubscription(recordType: FriendRequestStrings.recordType, predicate: predicate, options: [.firesOnRecordCreation])
        
        // Format the display of the notification
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.title = "New Friend Request"
        notificationInfo.alertBody = "You have received a friend request on MemeThing"
        notificationInfo.category = NotificationHelper.Category.newFriendRequest.rawValue
        //        notificationInfo.shouldBadge = true // TODO: - Not sure I like this behavior
        subscription.notificationInfo = notificationInfo
        
        // Save the subscription to the cloud
        CKService.shared.publicDB.save(subscription) { (_, _) in }
    }
    
    func subscribeToFriendRequestResponses() {
        // TODO: - User defaults to track whether the subscription has already been saved
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Form the predicate to look for friend requests sent from the current user that have been responded to
        let predicateFromSelf = NSPredicate(format: "%K == %@", argumentArray: [FriendRequestStrings.fromUsernameKey, currentUser.username])
        let predicateNoResponse = NSPredicate(format: "%K != %@", argumentArray: [FriendRequestStrings.statusKey, FriendRequest.Status.waiting.rawValue])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateFromSelf, predicateNoResponse])
        let subscription = CKQuerySubscription(recordType: FriendRequestStrings.recordType, predicate: predicate, options: [.firesOnRecordUpdate])
        
        // Format the display of the notification
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.title = "Response to Friend Request"
        notificationInfo.alertBody = "New response to friend request on MemeThing" // FIXME: - be able to change this based on status of friend request
        notificationInfo.category = NotificationHelper.Category.friendRequestResponse.rawValue
        //        notificationInfo.shouldBadge = true // TODO: - Not sure I like this behavior
        subscription.notificationInfo = notificationInfo
        
        // Save the subscription to the cloud
        CKService.shared.publicDB.save(subscription) { (_, _) in }
    }
    
    // MARK: - Send Notifications
    
    func sendFriendRequest(to user: User, completion: @escaping resultHandler) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Create the friend request
        let friendRequest = FriendRequest(fromReference: currentUser.reference, fromUsername: currentUser.username, toReference: user.reference, toUsername: user.username)
        
        // Save the friend request to the cloud
        CKService.shared.create(object: friendRequest) { [weak self] (result) in
            switch result {
            case .success(_):
                // Add the new friend request to the source of truth
                self?.outgoingFriendRequests?.append(friendRequest)
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
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Change the status of the friend request
        friendRequest.status = accept ? .accepted : .denied
        
        // Add the new friend to the list of friends, if accepted
        if accept {
            UserController.shared.update(currentUser, friendReference: friendRequest.fromReference) { (result) in
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
    
    // MARK: - Respond to Notifications
    
    func receiveResponseToFriendRequest() {
        print("got here to \(#function)")
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // First get the reference(s) to the requests sent by the current user that have been accepted or rejected
        let predicateFromSelf = NSPredicate(format: "%K == %@", argumentArray: [FriendRequestStrings.fromUsernameKey, currentUser.username])
        let predicateHasResponse = NSPredicate(format: "%K != %@", argumentArray: [FriendRequestStrings.statusKey, FriendRequest.Status.waiting.rawValue])
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateFromSelf, predicateHasResponse])
        print("predicate is \(compoundPredicate)")
        // Fetch the data from the cloud
        CKService.shared.read(predicate: compoundPredicate) { [weak self] (result: Result<[FriendRequest], MemeThingError>) in
            switch result {
            case .success(let friendRequests):
                print("got the friend requests and they are \(friendRequests)")
                for friendRequest in friendRequests { self?.handleResponse(to: friendRequest) }
            case .failure(let error):
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
    }
    
    // A helper function to handle responses to friend requests
    private func handleResponse(to friendRequest: FriendRequest) {
        guard let currentUser = UserController.shared.currentUser else { return }
        print("got here to \(#function) and friendRequest is \(friendRequest)")
        // If the friend accepted, add them to the user's list of friends
        if friendRequest.status == .accepted {
            UserController.shared.update(currentUser, friendReference: friendRequest.toReference) { (result) in
                // TODO: -
                print("updated the user with the new friend and the result is \(result)")
            }
        }
        
        // TODO: - display an alert to the user with the result of the friend request?? How would I do that?
        
        // Delete the friend request from the cloud now that it's no longer needed
        CKService.shared.delete(object: friendRequest) { [weak self] (result) in
            switch result {
            case .success(_):
                // Remove the friend request from the source of truth
                guard let index = self?.outgoingFriendRequests?.firstIndex(of: friendRequest) else { return }
                self?.outgoingFriendRequests?.remove(at: index)
                print("should have removed the friend request from the server and SoT, which is now \(self?.outgoingFriendRequests)")
            case .failure(let error):
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
        
        // TODO: - cause the tableview in the friends list to update automatically?
    }
}
