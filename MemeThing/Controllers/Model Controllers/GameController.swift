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
    
    // Create a new game from scratch
    func newGame(players: [User], completion: @escaping resultHandlerWithObject) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Create the new game with the current user as the first lead player
        var playerReferences = players.map { $0.reference }
        playerReferences.insert(currentUser.reference, at: 0)
        var playersNames = players.map { $0.screenName }
        playersNames.insert(currentUser.screenName, at: 0)
        let newGame = Game(playersReferences: playerReferences, playersNames: playersNames, leadPlayer: currentUser.reference)
        
        // Save the game to the cloud
        CKService.shared.create(object: newGame) { [weak self] (result) in
            switch result {
            case .success(let game):
                // Add the game to the source of truth
                if var currentGames = self?.currentGames {
                    currentGames.append(game)
                    self?.currentGames = currentGames
                } else {
                    self?.currentGames = [game]
                }
                
                // Return the success
                return completion(.success(game))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Create a new game from an old game
    func newGame(from oldGame: Game, completion: @escaping resultHandlerWithObject) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Remove the old game from the cloud
        delete(oldGame) { (_) in }
        
        // Use the data from the old game to start a new game, with the current user as the first lead player
        let activePlayers = oldGame.activePlayers
        var playerReferences = oldGame.playersReferences.filter { $0 != currentUser.reference && activePlayers.keys.contains($0.recordID.recordName) }
        playerReferences.insert(currentUser.reference, at: 0)
        let playerNames = playerReferences.compactMap { activePlayers[$0.recordID.recordName]?.name }
        
        let newGame = Game(playersReferences: playerReferences, playersNames: playerNames, leadPlayer: currentUser.reference, pointsToWin: oldGame.pointsToWin, recordID: CKRecord.ID(recordName: "\(oldGame.recordID)-2"))
        
        // Save the game to the cloud
        // FIXME: - need to handle a merge if someone else has already tried to restart the game
        saveChanges(to: newGame) { [weak self] (result) in
            switch result {
            case .success(let game):
                // Add the game to the source of truth
                if var currentGames = self?.currentGames {
                    currentGames.append(game)
                    self?.currentGames = currentGames
                } else {
                    self?.currentGames = [game]
                }
                
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
        let predicate = NSPredicate(format: "%@ IN %K", argumentArray: [currentUser.reference, GameStrings.playersReferencesKey])
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate])
        
        // Fetch the data from the cloud
        CKService.shared.read(predicate: compoundPredicate) { [weak self] (result: Result<[Game], MemeThingError>) in
            switch result {
            case .success(let games):
                // Save to the source of truth, filtering out the games that the user has declined, quit, or finished
                self?.currentGames = games.filter { $0.getStatus(of: currentUser) != .denied && $0.getStatus(of: currentUser) != .quit && $0.getStatus(of: currentUser) != .done }
                print("in completion and SoT contains \(games.count) games")
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
        print("got here to \(#function) and game being saved is \(game.debugging)")
        // Save the updated game to the cloud
        CKService.shared.update(object: game, overwrite: false) { [weak self] (result) in
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
                // If the error is that a merge is needed, handle that
                if case MemeThingError.mergeNeeded = error {
                    self?.handleMerge(for: game, completion: completion)
                }
                else {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            }
        }
    }
    
    // Helper method to handle merge conflicts between different games pushed to the cloud at the same time
    func handleMerge(for localGame: Game, completion: @escaping resultHandlerWithObject){
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        print("got here to \(#function)")
        
        // Fetch the updated game from the cloud
        fetchGame(from: localGame.recordID) { [weak self] (result) in
            switch result {
            case .success(let remoteGame):
                // Starting with the remote game's array, update just the indices of the current user's points and status
                print("remote game is \(remoteGame.debugging) and local game is \(localGame.debugging)")
                remoteGame.updateStatus(of: currentUser, to: localGame.getStatus(of: currentUser))
                remoteGame.updatePoints(of: currentUser, to: localGame.getPoints(of: currentUser))
                print("now remote game is \(remoteGame.debugging) and local game is \(localGame.debugging)")
                
                // If all players have seen the game, delete it from the cloud
                if remoteGame.allPlayersDone {
                    self?.delete(remoteGame, completion: { (result) in
                        switch result {
                        case .success(_):
                            // Return the success
                            return completion(.success(remoteGame))
                        case .failure(let error):
                            // Print and return the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            return completion(.failure(error))
                        }
                    })
                } else {
                    // Otherwise, use the newly merged data to recalculate the game's status
                    remoteGame.resetGameStatus()
                    //                if remoteGame.allPlayersResponded { remoteGame.gameStatus = .waitingForDrawing }
                    //                if remoteGame.allCaptionsSubmitted { remoteGame.gameStatus = .waitingForResult }
                    //                if remoteGame.gameWinner != nil { remoteGame.gameStatus = .gameOver }
                    print("finally, remote game is \(remoteGame.debugging) and local game is \(localGame.debugging)")
                    
                    // Try again to save the newly merged and updated game
                    self?.saveChanges(to: remoteGame, completion: completion)
                }
            case .failure(let error):
                // If the error is that a merge is needed again, handle that
                if case MemeThingError.mergeNeeded = error {
                    self?.handleMerge(for: localGame, completion: completion)
                }
                else {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            }
        }
    }
    
    // Delete a game when it's finished
    func delete(_ game: Game, completion: @escaping resultHandler) {
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
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // TODO: - User defaults to track whether the subscription has already been saved
        
        // Form the predicate to look for new games that include the current user in the players list
        let predicate = NSPredicate(format: "%@ IN %K", argumentArray: [currentUser.reference, GameStrings.playersReferencesKey])
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
    
//    // Subscribe all players to notifications of games they're participating in being deleted
//    func subscribeToGameEndings() {
//        guard let currentUser = UserController.shared.currentUser else { return }
//
//        // TODO: - User defaults to track whether the subscription has already been saved
//
//        // Form the predicate to look for games that include the current user in the players list
//        let predicate = NSPredicate(format: "%@ IN %K", argumentArray: [currentUser.reference, GameStrings.playersReferencesKey])
//        let subscription = CKQuerySubscription(recordType: GameStrings.recordType, predicate: predicate, options: [.firesOnRecordDeletion])
//
//        // Format the display of the notification
//        let notificationInfo = CKQuerySubscription.NotificationInfo()
//        notificationInfo.shouldSendContentAvailable = true
//        notificationInfo.category = NotificationHelper.Category.gameEnded.rawValue
//        subscription.notificationInfo = notificationInfo
//
//        // Save the subscription to the cloud
//        CKService.shared.publicDB.save(subscription) { (sub, error) in
////            print("got here to \(#function) and \(sub) and \(error)")
//        }
//    }
    
    // Subscribe all players to notifications of all updates to games they're participating in
    func subscribeToGameUpdates() {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // TODO: - User defaults to track whether the subscription has already been saved
        
        // Form the predicate to look for games that include the current user in the players list
        let predicate = NSPredicate(format: "%@ IN %K", argumentArray: [currentUser.reference, GameStrings.playersReferencesKey])
        let subscription = CKQuerySubscription(recordType: GameStrings.recordType, predicate: predicate, options: [.firesOnRecordUpdate])
        
        // Format the display of the notification
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.title = "Update to game"
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
                // Update the source of truth if it isn't already
                if !(self?.currentGames?.contains(game) ?? false) {
                    if var currentGames = self?.currentGames {
                        currentGames.append(game)
                        self?.currentGames = currentGames
                    } else {
                        self?.currentGames = [game]
                    }
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
        
        // Check that there's still enough players to be able to have a game, or start the game if everyone has responded
        game.resetGameStatus()
        
        // Save the updated game to the cloud
        saveChanges(to: game) { [weak self] (result) in
            switch result {
            case .success(let game):
                // If the user declined the invitation, remove the game from the source of truth
                if !accept { self?.handleEnd(for: game.recordID.recordName) }
                    
                // Tell the table view list of current games to update itself
                NotificationCenter.default.post(Notification(name: updateListOfGames))
                
                // Return the success
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
//    // Receive a notification that a game has ended
//    func receiveNotificationGameEnded(withID recordID: CKRecord.ID, completion: @escaping (UInt) -> Void) {
//        print("got here to \(#function)")
//        // Perform all the clean-up to finish the game
//        handleEnd(for: recordID.recordName)
//        
//        // Return the success
//        return completion(0)
//    }
    
    // Receive a notification that a game has been updated
    func receiveUpdateToGame(withID recordID: CKRecord.ID, completion: @escaping (UInt) -> Void) {
        guard let currentUser = UserController.shared.currentUser else { return completion(1) }
        print("got here to \(#function)")
        
        // Fetch the game object from the cloud
        fetchGame(from: recordID) { [weak self] (result) in
            switch result {
            case .success(let game):
                // Ignore updates to games that the user is not currently participating in
                let status = game.getStatus(of: currentUser)
                guard status != .quit && status != .denied else { return completion(0) }
                
                // Update the game in the source of truth
                guard let index = self?.currentGames?.firstIndex(of: game) else { return completion(0) }
                self?.currentGames?[index] = game
                
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
                guard let notificationName = notificationDestination else { return completion(0) }
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
    
    // Allow the user the quit the game at any time
    func quit(_ game: Game, completion: @escaping resultHandler) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Update the user's status
        game.updateStatus(of: currentUser, to: .quit)
        
        // FIXME: - need to confirm this works
        // Handle the flow of the gameplay, for example, if user quit in middle of a drawing or caption
        if game.leadPlayer.recordID.recordName == currentUser.recordID.recordName {
            game.resetGame()
        }
        game.resetGameStatus()
        
        // Save the update to the game
        saveChanges(to: game) { [weak self] (result) in
            switch result {
            case .success(let game):
                // Handle the clean up for leaving the game
                self?.handleEnd(for: game.recordID.recordName)
                
                // Return the success
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Allow the user to leave the game after it's finished
    func leave(_ game: Game, completion: @escaping resultHandler) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Update the user's status
        game.updateStatus(of: currentUser, to: .done)
        
        // If the user is the last one to leave the game, remove it from the cloud
        if game.allPlayersDone {
            delete(game) { [weak self] (result) in
                switch result {
                case .success(_):
                    // Handle the clean up for leaving the game
                    self?.handleEnd(for: game.recordID.recordName)
                    
                    // Return the success
                    return completion(.success(true))
                case .failure(let error):
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            }
        } else {
            // Otherwise, save the changes to the game
            saveChanges(to: game) { [weak self] (result) in
                switch result {
                case .success(_):
                    // Handle the clean up for leaving the game
                    self?.handleEnd(for: game.recordID.recordName)
                    
                    // Return the success
                    return completion(.success(true))
                case .failure(let error):
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            }
        }
    }
    
    // Perform all the cleanup for the user to exit the game, whether it's over or the user has quit
    func handleEnd(for gameRecordName: String) {
        print("got here to \(#function) and SoT has \(String(describing: currentGames?.count)) games")
        // Remove the game from the source of truth
        currentGames?.removeAll(where: { $0.recordID.recordName == gameRecordName })
        print("Now has \(String(describing: currentGames?.count)) games")
        
        // Tell the table view list of current games to update itself
        NotificationCenter.default.post(Notification(name: updateListOfGames))
    }
}
