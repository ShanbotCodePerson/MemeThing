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
    
    var currentGames: [Game]? // TODO: - could replace with a dictionary to make it easier to index by game id?
    
    // MARK: - Properties
    
    typealias resultHandler = (Result<Bool, MemeThingError>) -> Void
    typealias resultHandlerWithObject = (Result<Game, MemeThingError>) -> Void
    
    // MARK: - CRUD Methods
    
    // Create a new game
    func newGame(players: [User], completion: @escaping resultHandlerWithObject) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Create the new game with the current user as the default lead player
        var playerReferences = players.map { $0.reference }
        playerReferences.insert(currentUser.reference, at: 0)
        var playersNames = players.map { $0.screenName }
        playersNames.insert(currentUser.screenName, at: 0)
        let game = Game(players: playerReferences, playersNames: playersNames, leadPlayer: currentUser.reference)
        
        // Save the game to the cloud
        CKService.shared.create(object: game) { [weak self] (result) in
            switch result {
            case .success(let game):
                // Update the source of truth
                if var currentGames = self?.currentGames {
                    currentGames.append(game)
                    self?.currentGames = currentGames
                } else {
                    self?.currentGames = [game]
                }
                
                // Subscribe to updates for the game
                self?.subscribeToGameEndings(for: game)
                self?.subscribeToGameUpdates(for: game)
                
                // Return the success
                return completion(.success(game))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Read (fetch) all the games the user is currently involved in
    func fetchCurrentGames(completion: @escaping resultHandler) {
        print("got here to \(#function)")
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Create the query to only look for games where the current user is a player
        let predicate = NSPredicate(format: "%@ IN %K", argumentArray: [currentUser.reference, GameStrings.playersKey])
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate])
        
        // Fetch the data from the cloud
        CKService.shared.read(predicate: compoundPredicate) { [weak self] (result: Result<[Game], MemeThingError>) in
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
    
    // Read (fetch) a particular game from a reference
    func fetchGame(from recordID: CKRecord.ID, completion: @escaping resultHandlerWithObject) {
        // Fetch the data from the cloud
        CKService.shared.read(recordID: recordID) { (result: Result<Game, MemeThingError>) in
            switch result {
            case .success(let game):
                // Return the success
                return completion(.success(game))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Update a game
    func saveChanges(to game: Game, completion: @escaping resultHandlerWithObject) {
//        print("got here to \(#function) and game being saved is \(game.debugging)")
        // Save the updated game to the cloud
        CKService.shared.update(object: game) { [weak self] (result) in
            switch result {
            case .success(let game):
                // Update the game in the source of truth
                // FIXME: - this probably isn't necessary
                guard let index = self?.currentGames?.firstIndex(of: game) else { return completion(.failure(.unknownError)) }
                self?.currentGames?[index] = game
                print("got here to \(#function)")
                
                // Return the success
                return completion(.success(game))
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
    func subscribeToGameInvitations() {
        // TODO: - User defaults to track whether the subscription has already been saved
        
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Form the predicate to look for new games that include the current user in the players list
        let predicate = NSPredicate(format: "%@ IN %K", argumentArray: [currentUser.reference, GameStrings.playersKey])
        let subscription = CKQuerySubscription(recordType: GameStrings.recordType, predicate: predicate, options: [.firesOnRecordCreation])
        
        // Format the display of the notification
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.title = "New Game Invitation"
        notificationInfo.alertBody = "You have been invited to a new game on MemeThing"
        notificationInfo.shouldSendContentAvailable = true
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
        // Form the predicate to look for the specific game
        let predicate = NSPredicate(format: "%K == %@", argumentArray: ["recordID", game.recordID])
        let subscription = CKQuerySubscription(recordType: GameStrings.recordType, predicate: predicate,  subscriptionID: "\(game.recordID.recordName)-end", options: [CKQuerySubscription.Options.firesOnRecordDeletion])
        
        // Format the display of the notification
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.title = "Game Ended"
        notificationInfo.alertBody = "Your game on MemeThing has finished"
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.category = NotificationHelper.Category.gameEnded.rawValue
        subscription.notificationInfo = notificationInfo
        
        // Save the subscription to the cloud
        CKService.shared.publicDB.save(subscription) { (_, _) in }
    }
    
    // Subscribe all players to notifications of all updates to games they're participating in
    func subscribeToGameUpdates(for game: Game) {
        // TODO: - User defaults to track whether the subscription has already been saved
        
        // Form the predicate to look for the specific game
        let predicate = NSPredicate(format: "%K == %@", argumentArray: ["recordID", game.recordID])
        let subscription = CKQuerySubscription(recordType: GameStrings.recordType, predicate: predicate, subscriptionID: "\(game.recordID.recordName)-update", options: [CKQuerySubscription.Options.firesOnRecordUpdate])
        
        // Format the display of the notification
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.title = "Update to game" // TODO: - figure out a better message for this
        notificationInfo.alertBody =  "Update to a game you're playing"
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.category = NotificationHelper.Category.gameUpdate.rawValue
        subscription.notificationInfo = notificationInfo
        
        // Save the subscription to the cloud
        CKService.shared.publicDB.save(subscription) { (_, _) in }
    }
    
    // MARK: - Receive Notifications
    
    // Receive a notification that you've been invited to a game
    func receiveInvitationToGame(withID recordID: CKRecord.ID, completion: @escaping (UInt) -> Void) {
        print("got here to \(#function)")
        
        // TODO: - show an alert to the user
        
        // Fetch the game record from the cloud
        CKService.shared.read(recordID: recordID) { [weak self] (result: Result<Game, MemeThingError>) in
            switch result {
            case .success(let game):
                print("got here to \(#function) and game is \(game)")
                // Update the source of truth
                if var currentGames = self?.currentGames {
                    currentGames.append(game)
                    self?.currentGames = currentGames
                } else {
                    self?.currentGames = [game]
                }
                // Tell the table view list of current games to update itself
                NotificationCenter.default.post(Notification(name: updateListOfGames))
                
                // Return the success
                return completion(0)
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(2)
            }
        }
    }
    
    // Accept or decline an invitation to a game
    func respondToInvitation(to game: Game, accept: Bool, completion: @escaping resultHandler) {
        print("got here to \(#function)")
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Update the game with the user's response
        game.updateStatus(of: currentUser, to: (accept ? .accepted : .denied))
        
        // If all players have responded to the invitation, update the status of the game
        if game.allPlayersResponded {
            // Either start the game or end it depending on enough players accepted the invitation
            let status: Game.GameStatus = game.playersStatus.filter({ $0 == .accepted }).count >= 2 ? .waitingForDrawing : .gameOver
            // FIXME: - change the minimum number of players back to 3 after done testing
            game.gameStatus = status
        }
        
        // Save the updated game to the cloud
        saveChanges(to: game) { [weak self] (result) in
            switch result {
            case .success(let game):
                // If the user accepted the invitation, subscribe them to notifications for the game
                if accept {
                    self?.subscribeToGameEndings(for: game)
                    self?.subscribeToGameUpdates(for: game)
                }
                else {
                    // Otherwise, remove the game from the source of truth
                    guard let index = self?.currentGames?.firstIndex(of: game) else { return }
                    self?.currentGames?.remove(at: index)
                    
                    // Tell the table view list of current games to update itself
                    NotificationCenter.default.post(Notification(name: updateListOfGames))
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
    
    // Receive a notification that a game has ended
    func receiveNotificationGameEnded(withID recordID: CKRecord.ID, completion: @escaping (UInt) -> Void) {
        // TODO: - display an alert to the user
        
        // Get a reference to the game
        guard let index = currentGames?.firstIndex(where: { $0.recordID.recordName == recordID.recordName }),
            let game = currentGames?[index]
            else { return completion(2) }
        
        // Perform all the clean-up to finish the game
        handleEnd(for: game)
        
        // Return the success
        return completion(0)
    }
    
    // Receive a notification that a game has been updated
    func receiveUpdateToGame(withID recordID: CKRecord.ID, completion: @escaping (UInt) -> Void) {
        guard let currentUser = UserController.shared.currentUser else { return }
        print("got here to \(#function)")
        
        // Fetch the game object from the cloud
        fetchGame(from: recordID) { [weak self] (result) in
            switch result {
            case .success(let game):
//                print("SoT is \(self?.currentGames?.compactMap({$0.debugging})) and game is \(game.debugging)")
                // Update the game in the source of truth
                guard let index = self?.currentGames?.firstIndex(of: game) else { return }
                self?.currentGames?[index] = game
//                print("SoT is now \(self?.currentGames?.compactMap({$0.debugging}))")
                
                // Form the notification that will tell the views how to update
                var notificationDestination: Notification.Name?
                
                // Set the destination of the notification based on the status of the game
                switch game.gameStatus {
                case .waitingForPlayers:
                    // Tell the waiting view to update itself
                    notificationDestination = updateWaitingView
                case .waitingForDrawing:
                    // Tell the view (either the waiting view or the end of round view) to transition to a new round
                    notificationDestination = toNewRound
                case .waitingForCaptions:
                    // If the player has not submitted a caption yet, tell their view to transition to the captions view
                    if game.getStatus(of: currentUser) == .accepted {
                        notificationDestination = toCaptionsView
                    } else {
                        // Otherwise, tell the waiting view to update itself
                        notificationDestination = updateWaitingView
                    }
                case .waitingForResult:
                    // Tell the waiting view to transition to the results view
                    notificationDestination = toResultsView
                case .waitingForNextRound:
                    // Tell the results view to navigate to a new round
                    notificationDestination = toNewRound
                case .gameOver:
                    // Tell the results view to navigate to the game over view
                    notificationDestination = toGameOver
                }
                
                // Post the notification to update the view
                guard let notificationName = notificationDestination else { return }
                NotificationCenter.default.post(Notification(name: notificationName,  userInfo: ["gameID" : game.recordID.recordName]))
                print("notification sent with name \(notificationName)")
                
                // Return the success
                return completion(0)
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(2)
            }
        }
    }
    
    // MARK: - Helper Method
    
    // Allow the user the quit the game before it ends
    func quit(_ game: Game, completion: @escaping resultHandler) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Update the user's status
        game.updateStatus(of: currentUser, to: .quit)
        
        // Check to see if there are enough remaining active players, and if not, end the game
        if game.activePlayers.values.count < 3 { game.gameStatus = .gameOver }
        
        // Save the updates to the game
        saveChanges(to: game) { [weak self] (result) in
            switch result {
            case .success(let game):
                // Handle the clean up for leaving the game
                self?.handleEnd(for: game)
                
                // Return the success
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Perform all the cleanup to end the game, whether it's over or the user has quit
    func handleEnd(for game: Game) {
        // Remove the game from the source of truth
        currentGames?.removeAll(where: { $0 == game })
        
        // Remove the subscriptions to notifications for the game
        CKService.shared.publicDB.delete(withSubscriptionID: "\(game.recordID.recordName)-end") { (_, error) in
            if let error = error { print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)") }
        }
        CKService.shared.publicDB.delete(withSubscriptionID: "\(game.recordID.recordName)-update") { (_, error) in
            if let error = error { print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)") }
        }
        MemeController.shared.removeAllCaptionSubscriptions(for: game)
        
        // Tell the table view list of current games to update itself
        NotificationCenter.default.post(Notification(name: updateListOfGames))
        
        // If the user is currently in the game, transition them to the main menu
        NotificationCenter.default.post(Notification(name: toMainMenu, userInfo: ["gameID" : game.recordID.recordName]))
    }
}
