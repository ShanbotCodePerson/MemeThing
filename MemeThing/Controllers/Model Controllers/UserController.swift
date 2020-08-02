//
//  UserController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

// TODO: - find somewhere else to put this
typealias resultCompletion = (Result<Bool, MemeThingError>) -> Void
typealias resultCompletionWith<T> = (Result<T, MemeThingError>) -> Void

class UserController {
    
    // MARK: - Singleton
    
    static let shared = UserController()
    
    // MARK: - Source of Truth
    
    var currentUser: User?
    var usersFriends: [User]?
    
    // MARK: - Properties
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    // MARK: - CRUD Methods
    
    // Create a new user
    func createUser(with email: String, screenName: String?, completion: @escaping resultCompletion) {
        // Create the new user
        let user = User(email: email, screenName: screenName)
        
        let group = DispatchGroup()
        
        // Save the user object to the cloud and save the documentID for editing purposes
        group.enter()
        let reference: DocumentReference = db.collection(UserStrings.recordType).addDocument(data: user.asDictionary()) { (error) in
            
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.fsError(error)))
            }
            group.leave()
        }
        // FIXME: - threading issue here, but need reference outside
        user.documentID = reference.documentID
        
        // Save to the source of truth and return the success
        currentUser = user
        setUpUser()
        group.notify(queue: .main) { return completion(.success(true)) }
    }
    
    // Read (fetch) the current user
    func fetchUser(completion: @escaping resultCompletion) {
        guard let user = Auth.auth().currentUser, let email = user.email else { return completion(.failure(.noUserFound)) }
        
        db.collection(UserStrings.recordType)
            .whereField(UserStrings.emailKey, isEqualTo: email)
            .getDocuments { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents, documents.count > 0
                    else { return completion(.failure(.noUserFound)) }
                guard let document = documents.first,
                    let currentUser = User(dictionary: document.data())
                    else { return completion(.failure(.couldNotUnwrap)) }
                currentUser.documentID = document.documentID
                
                // Save to the source of truth and return the success
                self?.currentUser = currentUser
                self?.setUpUser()
                return completion(.success(true))
        }
    }
    
    // Read (fetch) all the friends of a user
    func fetchUsersFriends(completion: @escaping resultCompletion) {
        guard let currentUser = currentUser else { return completion(.failure(.noUserFound)) }
        
        // Return an empty array if the user has no friends
        if currentUser.friendIDs.count == 0 {
            self.usersFriends = []
            return completion(.success(false))
        }
        
        // Fetch the data from the cloud
        db.collection(UserStrings.recordType)
            .whereField(UserStrings.recordIDKey, in: currentUser.friendIDs)
            .getDocuments { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                let friends = documents.compactMap({ User(dictionary: $0.data()) })
                
                // Save to the source of truth and return the success
                self?.usersFriends = friends
                return completion(.success(true))
        }
    }
    
    // Read (search for) a specific user by an email
    func searchFor(_ email: String, completion: @escaping resultCompletionWith<User>) {
        // Fetch the data from the cloud
        db.collection(UserStrings.recordType)
            .whereField(UserStrings.emailKey, isEqualTo: email)
            .getDocuments { (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let document = results?.documents.first
                    else { return completion(.failure(.noSuchUser))}
                guard let friend = User(dictionary: document.data())
                    else { return completion(.failure(.couldNotUnwrap)) }
                
                // Return the success
                return completion(.success(friend))
        }
    }
    
    // Read (search for) a specific user by a recordID
    func fetchUser(by recordID: String, completion: @escaping resultCompletionWith<User>) {
        // Fetch the data from the cloud
        db.collection(UserStrings.recordType)
            .whereField(UserStrings.recordIDKey, isEqualTo: recordID)
            .getDocuments { (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let document = results?.documents.first,
                    let friend = User(dictionary: document.data())
                    else { return completion(.failure(.couldNotUnwrap)) }
                friend.documentID = document.documentID
                
                // Save to the source of truth and return the success
                return completion(.success(friend))
        }
    }
    
    // Update a user - generic helper function for other update functionality
    func saveChanges(to user: User, completion: @escaping resultCompletion) {
        guard let documentID = user.documentID else { return completion(.failure(.noUserFound)) }
        
        // Update the data in the cloud
        db.collection(UserStrings.recordType)
            .document(documentID)
            .updateData(user.asDictionary()) { [weak self] (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Update the source of truth
                self?.currentUser = user
                
                // Return the success
                return completion(.success(true))
        }
    }
    
    // Update a user with new profile information
    func update(_ user: User, screenName: String?, completion: @escaping resultCompletion) {
        // Update any fields that changed
        if let screenName = screenName { user.screenName = screenName }
        
        // Save the changes to the cloud
        saveChanges(to: user, completion: completion)
    }
    
    // Update a user's points
    func update(_ user: User, points: Int, completion: @escaping resultCompletion) {
        // Update the user's points
        user.points += points
        
        // Save the changes to the cloud
        saveChanges(to: user, completion: completion)
    }
    
    // Update a user with a new friend
    func update(_ user: User, friendID: String, completion: @escaping resultCompletion) {
        // Add the friend to the user's list of friends if it isn't already
        user.friendIDs.uniqueAppend(friendID)
        
        // Fetch the friend from the reference
        fetchUser(by: friendID) { [weak self] (result) in
            switch result {
            case .success(let friend):
                // Save the friend to the source of truth if it isn't already
                if self?.usersFriends?.uniqueAppend(friend) == nil {
                    self?.usersFriends = [friend]
                }
                
                // Tell the tableview in the friends list to update
                NotificationCenter.default.post(Notification(name: .friendsUpdate))
            case .failure(let error):
                // Print the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
        
        // Save the changes to the cloud
        saveChanges(to: user, completion: completion)
    }
    
    // Update a user with a new blocked id
    func update(_ user: User, IDToBlock ID: String, completion: @escaping resultCompletion) {
        // Add the username to the user's list of blocked usernames
        user.blockedIDs.append(ID)
        
        // Save the changes to the cloud
        saveChanges(to: user, completion: completion)
    }
    
    // Update a user by removing a friend
    func update(_ user: User, friendToRemove friendID: String, completion: @escaping resultCompletion) {
        // Remove the friend from the user's list of friends
        user.friendIDs.removeAll(where: { $0 == friendID })
        
        // Update the source of truth
        usersFriends?.removeAll(where: { $0.recordID == friendID })
        
        // Save the changes to the cloud
        saveChanges(to: user, completion: completion)
    }
    
    // Delete the current user
    func deleteCurrentUser(completion: @escaping resultCompletion) {
        guard let currentUser = currentUser,
            let documentID = currentUser.documentID
            else { return completion(.failure(.noUserFound)) }
        
        let group = DispatchGroup()
        
        // Delete all friend requests sent to or from the current user
        group.enter()
        FriendRequestController.shared.deleteAll { (result) in
            switch result {
            case .success(_):
                group.leave()
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
        
        // Quit the user out of any games they were playing
        if let games = GameController.shared.currentGames {
            for game in games {
                group.enter()
                GameController.shared.quit(game) { (result) in
                    switch result {
                    case .success(_):
                        group.leave()
                    case .failure(let error):
                        // Print and return the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        return completion(.failure(error))
                    }
                }
            }
        }
        
        // Remove the current user as a friend from all their friends
        if let friends = usersFriends {
            for friend in friends {
                group.enter()
                FriendRequestController.shared.sendRequestToRemove(friend) { (result) in
                    switch result {
                    case .success(_):
                        group.leave()
                    case .failure(let error):
                        // Print and return the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        return completion(.failure(error))
                    }
                }
            }
        }
        
        // Delete the user's account from the cloud
        group.enter()
        db.collection(UserStrings.recordType)
            .document(documentID)
            .delete() { (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                group.leave()
        }
        
        // Return the success
        group.notify(queue: .main) { return completion(.success(true)) }
    }
    
    // MARK: - Helper Methods
    
    // Set up all the necessary notification subscriptions for the user
    func setUpUser() {
        FriendRequestController.shared.subscribeToFriendRequestNotifications()
        FriendRequestController.shared.subscribeToFriendRequestResponseNotifications()
        FriendRequestController.shared.subscribeToRemovingFriendNotifications()
        
        GameController.shared.subscribeToGameNotifications()
    }
}
