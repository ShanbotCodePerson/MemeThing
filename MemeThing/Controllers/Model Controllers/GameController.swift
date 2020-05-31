//
//  GameController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/30/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit
import UIKit.UIImage

class GameController {
    
    // MARK: - Singleton
    
    static let shared = GameController()
    
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
                    self?.currentGames?.append(game)
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
    
    // Update a game with a new meme
    func createMeme(in game: Game, with photo: UIImage, by author: User, completion: @escaping resultHandler) {
        // Create the meme
        let meme = Meme(photo: photo, author: author.reference, game: game.reference)
        
        // Save it to the cloud
        CKService.shared.create(object: meme) { [weak self] (result) in
            switch result {
            case .success(let meme):
                // Update the source of truth
                guard let index = self?.currentGames?.firstIndex(of: game) else { return completion(.failure(.unknownError)) }
                self?.currentGames?[index].memes.append(meme.reference)
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Update a game with a new caption
    func createCaption(for meme: Meme, by author: User, with text: String, completion: @escaping resultHandler) {
        // Create the caption
        let caption = Caption(text: text, author: author.reference, meme: meme.reference)
        
        // Save it to the cloud
        CKService.shared.create(object: caption) { (result) in
            switch result {
            case .success(let caption):
                // Update the meme with the new caption
                meme.captions?.append(caption.reference)
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Update a game when a winning caption is selected
    func setWinningCaption(to caption: Caption, for meme: Meme, completion: @escaping resultHandler) {
        // Update the meme with the with the index of the winning caption
        meme.winningCaptionIndex = meme.captions?.firstIndex(of: caption.reference)
        
        CKService.shared.update(object: meme) { (result) in
            switch result {
            case .success(_):
                // Update the points of the author who wrote that caption
                // FIXME: - how do I do this??
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
    
    // MARK: - Notifications
    
    // Subscribe all players to notifications for games they're participating in
    
    // Respond to a notification that you've been invited to a game
    
    // Respond to a notification that a new meme has been pushed
    
    // Respond to a notification that a new caption has been pushed
}
