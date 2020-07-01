//
//  GameController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/30/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase

class GameController {
    
    // MARK: - Singleton
    
    static var shared = GameController()
    
    // MARK: - Source of Truth
    
    var currentGames: [Game]? // TODO: - could replace with a dictionary to make it easier to index by game id?
    
    // MARK: - CRUD Methods
    
    // Create a new game from scratch
    func newGame(players: [User], completion: @escaping resultCompletionWith<Game>) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Create the new game with the current user as the first lead player
        var playersIDS = players.map { $0.recordID }
        playersIDS.insert(currentUser.recordID, at: 0)
        var playersNames = players.map { $0.screenName }
        playersNames.insert(currentUser.screenName, at: 0)
        let game = Game(playersIDs: playersIDS, playersNames: playersNames, leadPlayerID: currentUser.recordID)
        
        // Save the game to the cloud
        let reference: DocumentReference = db.collection(GameStrings.recordType).addDocument(data: game.asDictionary()) { (error) in
            
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.fsError(error)))
            }
        }
        // FIXME: - threading issue here, but need reference outside
        game.documentID = reference.documentID
        
        // Add the game to the source of truth
        if var currentGames = self.currentGames {
            currentGames.append(game)
            self.currentGames = currentGames
        } else { self.currentGames = [game] }
        
        // Return the success
        return completion(.success(game))
    }
    
    // Create a new game from an old game
    func newGame(from oldGame: Game, completion: @escaping resultCompletionWith<Game>) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Remove the old game from the cloud
        delete(oldGame) { (_) in }
        
        // Use the data from the old game to start a new game, with the current user as the first lead player
        let activePlayers = oldGame.activePlayers
        var playersIDs = oldGame.playersIDs.filter { $0 != currentUser.recordID && activePlayers.keys.contains($0) }
        playersIDs.insert(currentUser.recordID, at: 0)
        let playerNames = playersIDs.compactMap { activePlayers[$0]?.name }
        
        let newGame = Game(playersIDs: playersIDs, playersNames: playerNames, leadPlayerID: currentUser.recordID, pointsToWin: oldGame.pointsToWin)
        
        // Save the game to the cloud
        let reference: DocumentReference = db.collection(GameStrings.recordType).addDocument(data: newGame.asDictionary()) { (error) in
            
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.fsError(error)))
            }
        }
        // FIXME: - threading issue here, but need reference outside
        newGame.documentID = reference.documentID
        
        // Add the game to the source of truth
        if var currentGames = self.currentGames {
            currentGames.append(newGame)
            self.currentGames = currentGames
        } else { self.currentGames = [newGame] }
        
        // Return the success
        return completion(.success(newGame))
    }
    
    // Read (fetch) all the games the user is currently involved in
    func fetchCurrentGames(completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Fetch all the games that include the user
        db.collection(GameStrings.recordType)
            .whereField(GameStrings.playersIDsKey, arrayContains: currentUser.recordID)
            .getDocuments { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents else { return completion(.failure(.couldNotUnwrap)) }
                let games = documents.compactMap { (document) -> Game? in
                    guard let game = Game(dictionary: document.data()) else { return nil }
                    game.documentID = document.documentID
                    return game
                }
                
                // Save to the source of truth, filtering out the games that the user has declined, quit, or finished
                self?.currentGames = games.filter { $0.getStatus(of: currentUser) != .denied && $0.getStatus(of: currentUser) != .quit && $0.getStatus(of: currentUser) != .done }
                return completion(.success(true))
        }
    }
    
    // Read (fetch) a particular game from a recordID
    func fetchGame(from recordID: String, completion: @escaping resultCompletionWith<Game>) {
        // Fetch the data from the cloud
        db.collection(GameStrings.recordType)
            .whereField(GameStrings.recordIDKey, isEqualTo: recordID)
            .getDocuments { (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let document = results?.documents.first,
                    let game = Game(dictionary: document.data())
                    else { return completion(.failure(.couldNotUnwrap)) }
                game.documentID = document.documentID
                
                // Return the success
                return completion(.success(game))
        }
    }
    
    // Update a game
    func saveChanges(to game: Game, completion: @escaping resultCompletionWith<Game>) {
        guard let documentID = game.documentID else { return completion(.failure(.noData)) }
        
        // Save the updated game to the cloud
        db.collection(GameStrings.recordType)
            .document(documentID)
            .setData(game.asDictionary()) { [weak self] (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Update the game in the source of truth
                // FIXME: - this probably isn't necessary
                guard let index = self?.currentGames?.firstIndex(of: game) else { return completion(.failure(.unknownError)) }
                self?.currentGames?[index] = game
                
                return completion(.success(game))
        }
        // FIXME: - merge conflicts?
    }
    
//    // Helper method to handle merge conflicts between different games pushed to the cloud at the same time
//    func handleMerge(for localGame: Game, completion: @escaping resultCompletionWith<Game>){
//        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
//        print("got here to \(#function)")
//
//        // Fetch the updated game from the cloud
//        fetchGame(from: localGame.recordID) { [weak self] (result) in
//            switch result {
//            case .success(let remoteGame):
//                // Starting with the remote game's array, update just the indices of the current user's points and status
//                print("remote game is \(remoteGame.debugging) and local game is \(localGame.debugging)")
//                remoteGame.updateStatus(of: currentUser, to: localGame.getStatus(of: currentUser))
//                remoteGame.updatePoints(of: currentUser, to: localGame.getPoints(of: currentUser))
//                print("now remote game is \(remoteGame.debugging) and local game is \(localGame.debugging)")
//
//                // If all players have seen the game, delete it from the cloud
//                if remoteGame.allPlayersDone {
//                    self?.delete(remoteGame, completion: { (result) in
//                        switch result {
//                        case .success(_):
//                            // Return the success
//                            return completion(.success(remoteGame))
//                        case .failure(let error):
//                            // Print and return the error
//                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
//                            return completion(.failure(error))
//                        }
//                    })
//                } else {
//                    // Otherwise, use the newly merged data to recalculate the game's status
//                    remoteGame.resetGameStatus()
//                    //                if remoteGame.allPlayersResponded { remoteGame.gameStatus = .waitingForDrawing }
//                    //                if remoteGame.allCaptionsSubmitted { remoteGame.gameStatus = .waitingForResult }
//                    //                if remoteGame.gameWinner != nil { remoteGame.gameStatus = .gameOver }
//                    print("finally, remote game is \(remoteGame.debugging) and local game is \(localGame.debugging)")
//
//                    // Try again to save the newly merged and updated game
//                    self?.saveChanges(to: remoteGame, completion: completion)
//                }
//            case .failure(let error):
//                // If the error is that a merge is needed again, handle that
//                if case MemeThingError.mergeNeeded = error {
//                    self?.handleMerge(for: localGame, completion: completion)
//                }
//                else {
//                    // Print and return the error
//                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
//                    return completion(.failure(error))
//                }
//            }
//        }
//    }
    
    // Delete a game when it's finished
    func delete(_ game: Game, completion: @escaping resultCompletion) {
        guard let documentID = game.documentID else { return completion(.failure(.noData)) }
        
        // Delete the data from the cloud
        db.collection(GameStrings.recordType)
            .document(documentID)
            .delete() { (error) in
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                return completion(.success(true))
                
                // FIXME: - delete all associated memes and captions
        }
    }
    
    // MARK: - Notifications
    
    // FIXME: - remote notifications, for when the app is closed
    
    
    // FIXME: - I think this same function will actually run for all game changes (creations, updates, and deletes)
    /// check to see when this function runs, and break out into helper functions as needed
    // Subscribe all players to notifications of invitations to games
    func subscribeToGameInvitations() {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Set up a listener to be alerted when any games are created that include the user in the list of players
        db.collection(GameStrings.recordType)
            .whereField(GameStrings.playersIDsKey, arrayContains: currentUser.recordID)
            .addSnapshotListener { (snapshot, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
                
                // Unwrap the data
                guard let documents = snapshot?.documents else { return }
                let games = documents.compactMap { (document) -> Game? in
                    guard let game = Game(dictionary: document.data()) else { return nil }
                    game.documentID = document.documentID
                    return game
                }
                
                // Save the new games to the source of truth
                
                // Display an alert to the user and update the list of games
        }
    }
    
//    // Subscribe all players to notifications of all updates to games they're participating in
//    func subscribeToGameUpdates() {
//        guard let currentUser = UserController.shared.currentUser else { return }
//        
//        // TODO: - User defaults to track whether the subscription has already been saved
//        
//        // Form the predicate to look for games that include the current user in the players list
//        let predicate = NSPredicate(format: "%@ IN %K", argumentArray: [currentUser.reference, GameStrings.playersReferencesKey])
//        let subscription = CKQuerySubscription(recordType: GameStrings.recordType, predicate: predicate, options: [.firesOnRecordUpdate])
//        
//        // Format the display of the notification
//        let notificationInfo = CKQuerySubscription.NotificationInfo()
//        notificationInfo.title = "Update to game"
//        notificationInfo.alertBody =  "Update to a game you're playing"
//        notificationInfo.shouldSendContentAvailable = true
//        notificationInfo.category = NotificationHelper.Category.gameUpdate.rawValue
//        subscription.notificationInfo = notificationInfo
//        
//        // Save the subscription to the cloud
//        CKService.shared.publicDB.save(subscription) { (_, _) in }
//    }
//    
//    // MARK: - Receive Notifications
//    
//    // Receive a notification that you've been invited to a game
//    func receiveInvitationToGame(withID recordID: CKRecord.ID, completion: @escaping (UInt) -> Void) {
//        print("got here to \(#function)")
//        
//        // TODO: - show an alert to the user
//        
//        // Fetch the game record from the cloud
//        CKService.shared.read(recordID: recordID) { [weak self] (result: Result<Game, MemeThingError>) in
//            switch result {
//            case .success(let game):
//                print("got here to \(#function) and game is \(game)")
//                // Update the source of truth if it isn't already
//                if !(self?.currentGames?.contains(game) ?? false) {
//                    if var currentGames = self?.currentGames {
//                        currentGames.append(game)
//                        self?.currentGames = currentGames
//                    } else {
//                        self?.currentGames = [game]
//                    }
//                }
//                
//                // Tell the table view list of current games to update itself
//                NotificationCenter.default.post(Notification(name: updateListOfGames))
//                
//                // Return the success
//                return completion(0)
//            case .failure(let error):
//                // Print and return the error
//                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
//                return completion(2)
//            }
//        }
//    }
//    
//    // Accept or decline an invitation to a game
//    func respondToInvitation(to game: Game, accept: Bool, completion: @escaping resultHandler) {
//        print("got here to \(#function)")
//        guard let currentUser = UserController.shared.currentUser else { return }
//        
//        // Update the game with the user's response
//        game.updateStatus(of: currentUser, to: (accept ? .accepted : .denied))
//        
//        // Check that there's still enough players to be able to have a game, or start the game if everyone has responded
//        game.resetGameStatus()
//        
//        // Save the updated game to the cloud
//        saveChanges(to: game) { [weak self] (result) in
//            switch result {
//            case .success(let game):
//                // If the user declined the invitation, remove the game from the source of truth
//                if !accept { self?.handleEnd(for: game.recordID.recordName) }
//                    
//                // Tell the table view list of current games to update itself
//                NotificationCenter.default.post(Notification(name: updateListOfGames))
//                
//                // Return the success
//                return completion(.success(true))
//            case .failure(let error):
//                // Print and return the error
//                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
//                return completion(.failure(error))
//            }
//        }
//    }
//    
//    // Receive a notification that a game has been updated
//    func receiveUpdateToGame(withID recordID: CKRecord.ID, completion: @escaping (UInt) -> Void) {
//        guard let currentUser = UserController.shared.currentUser else { return completion(1) }
//        print("got here to \(#function)")
//        
//        // Fetch the game object from the cloud
//        fetchGame(from: recordID) { [weak self] (result) in
//            switch result {
//            case .success(let game):
//                // Ignore updates to games that the user is not currently participating in
//                let status = game.getStatus(of: currentUser)
//                guard status != .quit && status != .denied else { return completion(0) }
//                
//                // Update the game in the source of truth
//                guard let index = self?.currentGames?.firstIndex(of: game) else { return completion(0) }
//                self?.currentGames?[index] = game
//                
//                // Form the notification that will tell the views how to update
//                var notificationDestination: Notification.Name?
//                
//                // Set the destination of the notification based on the status of the game
//                switch game.gameStatus {
//                case .waitingForPlayers:
//                    // Tell the waiting view to update itself
//                    notificationDestination = updateWaitingView
//                case .waitingForDrawing:
//                    // Tell the view (either the waiting view or the end of round view) to transition to a new round
//                    notificationDestination = toNewRound
//                case .waitingForCaptions:
//                    // If the player has not submitted a caption yet, tell their view to transition to the captions view
//                    if game.getStatus(of: currentUser) == .accepted {
//                        notificationDestination = toCaptionsView
//                    } else {
//                        // Otherwise, tell the waiting view to update itself
//                        notificationDestination = updateWaitingView
//                    }
//                case .waitingForResult:
//                    // Tell the waiting view to transition to the results view
//                    notificationDestination = toResultsView
//                case .waitingForNextRound:
//                    // Tell the results view to navigate to a new round
//                    notificationDestination = toNewRound
//                case .gameOver:
//                    // Tell the results view to navigate to the game over view
//                    notificationDestination = toGameOver
//                }
//                
//                // Post the notification to update the view
//                guard let notificationName = notificationDestination else { return completion(0) }
//                NotificationCenter.default.post(Notification(name: notificationName,  userInfo: ["gameID" : game.recordID.recordName]))
//                print("notification sent with name \(notificationName)")
//                
//                // Return the success
//                return completion(0)
//            case .failure(let error):
//                // Print and return the error
//                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
//                return completion(2)
//            }
//        }
//    }
//    
//    // MARK: - Helper Method
//    
//    // Allow the user the quit the game at any time
//    func quit(_ game: Game, completion: @escaping resultHandler) {
//        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
//        
//        // Update the user's status
//        game.updateStatus(of: currentUser, to: .quit)
//        
//        // FIXME: - need to confirm this works
//        // Handle the flow of the gameplay, for example, if user quit in middle of a drawing or caption
//        if game.leadPlayer.recordID.recordName == currentUser.recordID.recordName {
//            game.resetGame()
//        }
//        game.resetGameStatus()
//        
//        // Save the update to the game
//        saveChanges(to: game) { [weak self] (result) in
//            switch result {
//            case .success(let game):
//                // Handle the clean up for leaving the game
//                self?.handleEnd(for: game.recordID.recordName)
//                
//                // Return the success
//                return completion(.success(true))
//            case .failure(let error):
//                // Print and return the error
//                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
//                return completion(.failure(error))
//            }
//        }
//    }
//    
//    // Allow the user to leave the game after it's finished
//    func leave(_ game: Game, completion: @escaping resultHandler) {
//        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
//        
//        // Update the user's status
//        game.updateStatus(of: currentUser, to: .done)
//        
//        // If the user is the last one to leave the game, remove it from the cloud
//        if game.allPlayersDone {
//            delete(game) { [weak self] (result) in
//                switch result {
//                case .success(_):
//                    // Handle the clean up for leaving the game
//                    self?.handleEnd(for: game.recordID.recordName)
//                    
//                    // Return the success
//                    return completion(.success(true))
//                case .failure(let error):
//                    // Print and return the error
//                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
//                    return completion(.failure(error))
//                }
//            }
//        } else {
//            // Otherwise, save the changes to the game
//            saveChanges(to: game) { [weak self] (result) in
//                switch result {
//                case .success(_):
//                    // Handle the clean up for leaving the game
//                    self?.handleEnd(for: game.recordID.recordName)
//                    
//                    // Return the success
//                    return completion(.success(true))
//                case .failure(let error):
//                    // If the error is that the game has already been deleted, then saving the game is no longer relevant
//                    if case MemeThingError.alreadyDeleted = error { return completion(.success(true)) }
//                    
//                    // Otherwise, print and return the error
//                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
//                    return completion(.failure(error))
//                }
//            }
//        }
//    }
//    
//    // Perform all the cleanup for the user to exit the game, whether it's over or the user has quit
//    func handleEnd(for gameRecordName: String) {
//        print("got here to \(#function) and SoT has \(String(describing: currentGames?.count)) games")
//        // Remove the game from the source of truth
//        currentGames?.removeAll(where: { $0.recordID.recordName == gameRecordName })
//        print("Now has \(String(describing: currentGames?.count)) games")
//        
//        // Tell the table view list of current games to update itself
//        NotificationCenter.default.post(Notification(name: updateListOfGames))
//    }
}
