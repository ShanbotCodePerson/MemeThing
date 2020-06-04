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
    typealias resultHandlerWithObject = (Result<Game, MemeThingError>) -> Void
    
    // MARK: - CRUD Methods
    
    // Create a new game
    func newGame(players: [User], completion: @escaping resultHandler) {
        // Get the reference for the current user
        UserController.shared.fetchAppleUserReference { [weak self] (reference) in
            guard let reference = reference else { return completion(.failure(.noUserFound)) }
            
            // Create the new game with the current user as the default lead player
            var playerReferences = players.map({ $0.reference })
            playerReferences.insert(reference, at: 0)
            let game = Game(players: playerReferences, leadPlayer: reference)
            
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
    func fetchGame(from recordID: CKRecord.ID, completion: @escaping resultHandlerWithObject) {
        // Fetch the data from the cloud
        CKService.shared.read(recordID: recordID) { [weak self] (result: Result<Game, MemeThingError>) in
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
                return completion(.success(game))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // TODO: - Update a game with new data of any sort? separate functions for each? different types of updates?
    
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
        let subscription = CKQuerySubscription(recordType: GameStrings.recordType, predicate: predicate, options: [.firesOnRecordDeletion])
        // FIXME: - use a subscriptionID so that the subscription can be deleted when the game is over
        
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
        let subscription = CKQuerySubscription(recordType: GameStrings.recordType, predicate: predicate, options: [.firesOnRecordUpdate])
        // FIXME: - use a subscriptionID so that the subscription can be deleted when the game is over
        
        // Format the display of the notification
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.title = "New Game Invitation"
        notificationInfo.alertBody = "You have been invited to a new game on MemeThing"
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.category = NotificationHelper.Category.gameUpdate.rawValue
        subscription.notificationInfo = notificationInfo
        
        // Save the subscription to the cloud
        CKService.shared.publicDB.save(subscription) { (_, _) in }
    }
    
    // MARK: - Receive Notifications
    
    // Receive a notification that you've been invited to a game
    func receiveInvitationToGame(withID recordID: CKRecord.ID) {
        // TODO: - show an alert to the user
        // TODO: - fetch the game record
        // TODO: - add it to the source of truth
        // TODO: - tell the table view list of current games to update itself
        print("got here to \(#function)")
    }
    
    // Accept or decline an invitation to a game
    func respondToInvitation(to game: Game, accept: Bool, completion: @escaping resultHandler) {
        // TODO: - make the change to the game object
        // TODO: - save the updates to the cloud
        // TODO: - if declined, remove the game from the source of truth
        // TODO: - if accepted, subscribe to updates and ending notifications for the game
        // TODO: - tell the table view list of current games to update itself
    }
    
    // Receive a notification that a game has ended
    func receiveNotificationGameEnded(withID recordID: CKRecord.ID) {
        // TODO: - display an alert to the user
        // TODO: - remove the game from the source of truth
        // TODO: - remove the subscriptions to notifications for the game
        // TODO: - tell the table view list of current games to update itself
    }
    
    // Receive a notification that a game has been updated
    func receiveUpdateToGame(withID recordID: CKRecord.ID) {
        // TODO: - show an alert to user if applicable? (ie, if they're on a different view)
        
        // Fetch the game object from the cloud
        fetchGame(from: recordID) { [weak self] (result) in
            switch result {
            case .success(let game):
                // Call the relevant helper method based on the status of the game
                switch game.gameStatus {
                case .waitingForPlayers:
                    self?.waitingForPlayers(for: game)
                case .waitingForDrawing:
                    self?.newRoundStarted(for: game)
                case .waitingForCaptions:
                    self?.drawingSent(for: game)
                case .waitingForResult:
                    self?.receivedAllCaptions(for: game)
                case .waitingForNextRound:
                    self?.winningCaptionSelected(for: game)
                case .gameOver:
                    self?.handleFinish(for: game)
                }
            case .failure(let error):
                // Print the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                // TODO: - better error handling  - display an alert to the user?
            }
        }
    }
    
    // MARK: - Handle Game Updates
    
    // TODO: - transition to the correct view, or update views or stuff
    
    // Player status changed - accepted game invite
    func waitingForPlayers(for game: Game) {
        // TODO: - update the waiting view to reflect the player's response
        // TODO: - check if all players have responded to the game invite yet
        // TODO: - if all have responded:
            // TODO: - change game status to waitingfordrawing
            // TODO: - save updated game to cloud
        print("got here to \(#function)")
        // TODO: - display a loading icon while the views load?
    }
    
    // Round started
    func newRoundStarted(for game: Game) {
        // TODO: - if lead player, change view to drawing view
        // TODO: - else, change view to updated waiting view
        print("got here to \(#function)")
    }
    
    // Either the drawing has just been sent or a caption has been received
    func drawingSent(for game: Game) {
        // TODO: - check if all the captions have been received yet
        // TODO: - if not all captions received yet
            // TODO: - if lead player, update waiting view to show how many players you're waiting for
            // TODO: - else, change view to waiting view
        // TODO: - if all captions received:
            // TODO: - update game status to waitingforresult
            // TODO: - save updated game to cloud
        print("got here to \(#function)")
    }
    // TODO: - when user sends a drawing, need to update game status to waiting for caption, set own status to .sentdrawing, save game to cloud
    // So all the above has been done by the time the function drawingSent() has been called
    
    // All the captions have been received
    func receivedAllCaptions(for game: Game) {
        // TODO: - show results page (leader has button to choose winner, otherwise same for all)
        print("got here to \(#function)")
    }
    
    // Winning caption selected
    func winningCaptionSelected(for game: Game) {
        // TODO: - check if there's an overall winner of the game yet
        // TODO: - if winner of game
            // TODO: - update status of game to gameover
            // TODO: - save updated game to cloud
        // TODO: - else if no winner yet
            // TODO: - update game status to waitingfordrawing
            // TODO: - update leadplayer to next player in line
            // TODO: - update all (active) players to .accepted status
            // TODO: - save updated game to cloud
        print("got here to \(#function)")
    }
    // TODO: - when player selects a winner, need to update that in meme's data, update user points in user object and game object, update game status to waitingfornextround, save changes to cloud
    // So all the above has been done by the time the function winningCaptionSelected() has been called
    
    // Game over
    func handleFinish(for game: Game) {
        // TODO: - display results to users
        // I dunno some fancy animation or something make it look pretty
        // TODO: - delete game object
        // TODO: - return all users to main menu view
        print("got here to \(#function)")
    }
}
