//
//  GameController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/30/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit

class GameController {
    
    // MARK: - Singleton
    
    static var shared = GameController()
    
    // MARK: - Source of Truth
    
    var currentGames: [Game]?
    
    // MARK: - Properties
    
    typealias resultHandler = (Result<Bool, MemeThingError>) -> Void
    
    // MARK: - CRUD Methods
    
    // Create a new game
    func newGame(players: [User], completion: @escaping resultHandler) {
        // Get the reference for the current user
        UserController.shared.fetchAppleUserReference { [weak self] (reference) in
            guard let reference = reference else { return completion(.failure(.noUserFound)) }
            
            // Create the new game with the current user as the default lead player
            let game = Game(players: players.map({ $0.reference }), leadPlayer: reference)
            
            // Save the game to the cloud
            CKService.shared.create(object: game) { (result) in
                switch result {
                case .success(let game):
                    // Update the source of truth
                    if var currentGames = self?.currentGames {
                        currentGames.append(game)
                        self?.currentGames = currentGames
                    } else {
                        self?.currentGames = [game]
                    }
                    return completion(.success(true))
                case .failure(let error):
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            }
        }
    }
    
    // Read (fetch) all the games the user is currently involved in
    func fetchCurrentGames(completion: @escaping resultHandler) {
        print("got here to \(#function)")
        // Get the reference for the current user
        UserController.shared.fetchAppleUserReference { [weak self] (reference) in
            guard let reference = reference else { return completion(.failure(.noUserFound)) }
            
            // Create the query to only look for games where the current user is a player
            // FIXME: - make sure this works
            let predicate = NSPredicate(format: "%K IN %@", argumentArray: [reference, GameStrings.playersKey])
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate])
            
            // Fetch the data from the cloud
            CKService.shared.read(predicate: compoundPredicate) { (result: Result<[Game], MemeThingError>) in
                switch result {
                case .success(let games):
                    print("in completion and fetched games are \(games)")
                    // Save to the source of truth
                    self?.currentGames = games
                    return completion(.success(true))
                case .failure(let error):
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            }
        }
    }
    
    // Read (fetch) a particular game from a reference
    func fetchGame(from reference: CKRecord.Reference, completion: @escaping resultHandler) {
        // TODO: -
        CKService.shared.read(reference: reference) { [weak self] (result: Result<Game, MemeThingError>) in
            switch result {
            case .success(let game):
                // Update the source of truth
                if let index = self?.currentGames?.firstIndex(of: game) {
                    // If the game is already in the array, replace it with this updated version
                    self?.currentGames?.remove(at: index)
                    self?.currentGames?.insert(game, at: index)
                } else {
                    // Otherwise, add the game to the array for the first time
                    if var currentGames = self?.currentGames {
                        currentGames.append(game)
                        self?.currentGames = currentGames
                    } else {
                        self?.currentGames = [game]
                    }
                }
                // Return the success
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Update a game's status
    func updateStatus(of game: Game, to status: Game.GameStatus, completion: @escaping resultHandler) {
        // Update the game's status
        game.gameStatus = status
        
        // Save the changes to the cloud
        CKService.shared.update(object: game) { (result) in
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
    
    // Delete a game when it's finished
    func finishGame(_ game: Game, completion: @escaping resultHandler) {
        CKService.shared.delete(object: game) { (result) in
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
    
    // MARK: - Subscribe to Notifications
    
    // Subscribe all players to notifications of invitations to games
    // TODO: - need to call this from somewhere
    func subscribeToGameInvitations() {
        // TODO: - User defaults to track whether the subscription has already been saved
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Form the predicate to look for new games that include the current user in the players list
        // TODO: - exclude ones created by self?
//        let predicate = NSPredicate(format: "%K IN %@", argumentArray: [currentUser.recordID, GameStrings.playersKey])
//        let predicate = NSPredicate(format: "%K CONTAINS[c] %@", argumentArray: [GameStrings.playersKey, currentUser.recordID])
        let predicate = NSPredicate(format: "%@ IN %K", argumentArray: [currentUser.reference, GameStrings.playersKey])
        // FIXME: - what's the correct predicate here?
        let subscription = CKQuerySubscription(recordType: GameStrings.recordType, predicate: predicate, options: [.firesOnRecordCreation])
        
        // Format the display of the notification
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.title = "New Game Invitation"
        notificationInfo.alertBody = "You have been invited to a new game on MemeThing"
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = ["leadPlayer"] // TODO: - replace with actually useful data
        notificationInfo.category = NotificationHelper.Category.newGameInvitation.rawValue
        subscription.notificationInfo = notificationInfo
        
        // Save the subscription to the cloud
        CKService.shared.publicDB.save(subscription) { (sub, error) in
//             TODO: -delete all these extra print statements
//            print("got here to \(#function) and \(sub) and \(error?.localizedDescription)")
        }
    }
    
    // Subscribe all players to notifications of games they're participating in being deleted
    func subscribeToGameEndings(for game: Game) {
        
    }
    
    // Subscribe all players to notifications of all updates to games they're participating in
    func subscribeToGameUpdates(for game: Game) {
        // TODO: - User defaults to track whether the subscription has already been saved
        
        // Form the predicate to look for the specific game
        // TODO: - exclude ones created by self?
        let predicate = NSPredicate(format: "%K == %@", argumentArray: ["recordID", game.recordID])
        let subscription = CKQuerySubscription(recordType: GameStrings.recordType, predicate: predicate, options: [.firesOnRecordUpdate])
        
        // Format the display of the notification
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.title = "New Game Invitation"
        notificationInfo.alertBody = "You have been invited to a new game on MemeThing"
        notificationInfo.category = NotificationHelper.Category.newGameInvitation.rawValue
        subscription.notificationInfo = notificationInfo
        
        // Save the subscription to the cloud
        CKService.shared.publicDB.save(subscription) { (_, _) in }
    }
    
    // MARK: - Receive Notifications
    
    // Receive a notification that you've been invited to a game
    func receiveGameInvitation() {
        // TODO: -if accepted, subscribe to updates for the game
        print("got here to \(#function)")
    }
    
    // Receive a notification that a game has ended
    
    // Receive a notification that a game has been updated
    
    // MARK: - Respond to Game Updates
    
    // Player status changed - accepted game invite
    
    // Meme pushed
    
    // Player status changed - sent caption
    
    // Winning caption selected
    
    // New round
}
