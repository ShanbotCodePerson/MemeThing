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
    
    var currentGames: [Game]?
    
    // MARK: - Properties
    
    let db = Firestore.firestore()
    
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
        if currentGames?.append(game) == nil { currentGames = [game] }
        
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
        if currentGames?.append(newGame) == nil { currentGames = [newGame] }
        
        // Return the success
        return completion(.success(newGame))
    }
    
    // Read (fetch) all the games the user is currently involved in
    func fetchCurrentGames(completion: @escaping resultCompletionWith<[Game]>) {
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
                var games = documents.compactMap { (document) -> Game? in
                    guard let game = Game(dictionary: document.data()) else { return nil }
                    game.documentID = document.documentID
                    return game
                }
                
                // Save to the source of truth, filtering out the games that the user has declined, quit, or finished
                games = games.filter { $0.getStatus(of: currentUser) != .denied && $0.getStatus(of: currentUser) != .quit && $0.getStatus(of: currentUser) != .done }
                self?.currentGames = games
                return completion(.success(games))
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
    
    // Update a game by accepting or declining an invitation
    func respondToInvitation(to game: Game, accept: Bool, completion: @escaping resultCompletion) {
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
                if !accept { self?.handleEnd(for: game) }
                
                // Tell the table view list of current games to update itself
                NotificationCenter.default.post(Notification(name: .updateListOfGames))
                
                // Return the success
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Update the game by allowing the user the quit at any time
    func quit(_ game: Game, completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Update the user's status
        game.updateStatus(of: currentUser, to: .quit)
        
        // FIXME: - need to confirm this works
        // Handle the flow of the gameplay, for example, if user quit in middle of a drawing or caption
        if game.leadPlayerID == currentUser.recordID { game.resetGame() }
        game.resetGameStatus()
        
        // Save the update to the game
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
    
    // Allow the user to leave the game after it's finished
    func leave(_ game: Game, completion: @escaping resultCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return completion(.failure(.noUserFound)) }
        
        // Update the user's status
        game.updateStatus(of: currentUser, to: .done)
        
        // If the user is the last one to leave the game, remove it from the cloud
        if game.allPlayersDone {
            delete(game) { [weak self] (result) in
                switch result {
                case .success(_):
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
        } else {
            // Otherwise, save the changes to the game
            saveChanges(to: game) { [weak self] (result) in
                switch result {
                case .success(_):
                    // Handle the clean up for leaving the game
                    self?.handleEnd(for: game)
                    
                    // Return the success
                    return completion(.success(true))
                case .failure(let error):
                    // If the error is that the game has already been deleted, then saving the game is no longer relevant
                    if case MemeThingError.alreadyDeleted = error { return completion(.success(true)) }
                    
                    // Otherwise, print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(error))
                }
            }
        }
    }
    
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
                
                let group = DispatchGroup()
                
                // Delete all the memes and captions associated with the game
                group.enter()
                MemeController.shared.deleteAllMemes(in: game) { (result) in
                    switch result {
                    case .success(_):
                        group.leave()
                    case .failure(let error):
                        // Print and return the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        return completion(.failure(error))
                    }
                }
                group.enter()
                MemeController.shared.deleteAllCaptions(in: game) { (result) in
                    switch result {
                    case .success(_):
                        group.leave()
                    case .failure(let error):
                        // Print and return the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        return completion(.failure(error))
                    }
                }
                
                // Return the success
                group.notify(queue: .main) { return completion(.success(true)) }
        }
    }
    
    // MARK: - Notifications
    
    // FIXME: - remote notifications, for when the app is closed
    
    // Subscribe all players to notifications related to games
    func subscribeToGameNotifications() {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Set up a listener to be alerted when any games are created that include the user in the list of players
        db.collection(GameStrings.recordType)
            .whereField(GameStrings.playersIDsKey, arrayContains: currentUser.recordID)
            .addSnapshotListener { [weak self] (snapshot, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
                
                snapshot?.documentChanges.forEach({ (change) in
                    // Unwrap the data
                    guard let game = Game(dictionary: change.document.data()) else { return }
                    game.documentID = change.document.documentID
                    
                    // Make sure the game is one the user is actively participating in
                    let status = game.getStatus(of: currentUser)
                    guard status != .denied, status != .quit, status != .done else { return }
                    
                    switch change.type {
                    case .added:
                        // The user has been invited to a game
                        self?.handleInvitation(to: game)
                    case .modified:
                        // A game the user is playing has been updated
                        self?.handleUpdate(to: game)
                    case .removed:
                        // A game the user was involved in has ended
                        self?.handleDeletion(of: game)
                    }
                })
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleInvitation(to game: Game) {
        // Update the source of truth if it doesn't already contain the game
        if currentGames?.uniqueAppend(game) == nil { currentGames = [game] }
        
        // Tell the table view list of current games to update itself and show an alert to the user
        NotificationCenter.default.post(Notification(name: .updateListOfGames))
        
        // Create a notification to display if the user is looking at a different view
        // FIXME: - check what view the user is currently on
        NotificationHelper.createGameInvitationNotification(game)
    }
    
    private func handleUpdate(to game: Game) {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Ignore updates to games that the user is not currently participating in
        let status = game.getStatus(of: currentUser)
        guard status != .quit && status != .denied else { return }
        
        // Update the game in the source of truth
        guard let index = currentGames?.firstIndex(of: game) else { return }
        currentGames?[index] = game
        
        // Form the notification that will tell the views how to update
        var notificationDestination: Notification.Name?
        
        // Set the destination of the notification based on the status of the game
        switch game.gameStatus {
        case .waitingForPlayers:
            // Tell the waiting view to update itself
            notificationDestination = .updateWaitingView
        case .waitingForDrawing:
            // Tell the view (either the waiting view or the end of round view) to transition to a new round
            notificationDestination = .toNewRound
        case .waitingForCaptions:
            // If the player has not submitted a caption yet, tell their view to transition to the captions view
            if game.getStatus(of: currentUser) == .accepted {
                notificationDestination = .toCaptionsView
            } else {
                // Otherwise, tell the waiting view to update itself
                notificationDestination = .updateWaitingView
            }
        case .waitingForResult:
            // Tell the waiting view to transition to the results view
            notificationDestination = .toResultsView
        case .waitingForNextRound:
            // Tell the results view to navigate to a new round
            notificationDestination = .toNewRound
        case .gameOver:
            // Tell the results view to navigate to the game over view
            notificationDestination = .toGameOver
        }
        
        // Post the notification to update the view
        guard let notificationName = notificationDestination else { return }
        NotificationCenter.default.post(Notification(name: notificationName, userInfo: ["gameID" : game.recordID]))
        
        // Create a notification to display if the user is looking at a different view
        // FIXME: - check what view the user is currently on
        // FIXME: - only use this notification when it's the user's turn next
        NotificationHelper.createGameUpdateNotification(game)
    }
    
    private func handleDeletion(of game: Game) {
        // Transition back to the main menu if the user was currently viewing the end of game screen
        NotificationCenter.default.post(Notification(name: .toMainMenu, userInfo: ["gameID" : game.recordID]))
        
        // Handle any necessary clean up for leaving the game
        handleEnd(for: game)
    }
    
    // Perform all the cleanup for the user to exit the game, whether it's over or the user has quit
    private func handleEnd(for game: Game) {
        // Make sure to update the user's points with however many points they earned in the game
        if let currentUser = UserController.shared.currentUser {
            let points = game.getPoints(of: currentUser)
            UserController.shared.update(currentUser, points: points) { (result) in
                switch result {
                case .success(_):
                    print("should have incremented users points, now is \(currentUser.points)")
                case .failure(let error):
                    // Print the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return
                }
            }
        }
        
        // Remove the game from the source of truth
        currentGames?.removeAll(where: { $0 == game })
        
        // Tell the table view list of current games to update itself
        NotificationCenter.default.post(Notification(name: .updateListOfGames))
        
        // Create a notification to display if the user is looking at a different view
        // FIXME: - check what view the user is currently on
        NotificationHelper.createGameOverNotification(game)
    }
}
