//
//  MemeController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/3/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit
import UIKit.UIImage

class MemeController {
    
    // MARK: - Singleton
    
    static let shared = MemeController()
    
    // MARK: - Properties
    
    typealias resultHandler = (Result<Bool, MemeThingError>) -> Void
    
    // MARK: - CRUD Methods
    
    // Create a new meme
    func createMeme(in game: Game, with photo: UIImage, by author: User, completion: @escaping resultHandler) {
        // Create the meme
        let meme = Meme(photo: photo, author: author.reference, game: game.reference)
        
        // Save it to the cloud
        CKService.shared.create(object: meme) { (result) in
            switch result {
            case .success(let meme):
                // Update the source of truth
                guard let index = GameController.shared.currentGames?.firstIndex(of: game) else { return completion(.failure(.unknownError)) }
                // FIXME: can't append to empty array
                GameController.shared.currentGames?[index].memes?.append(meme.reference)
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Read (fetch) a meme from a reference
    func fetchMeme(from reference: CKRecord.Reference, completion: @escaping (Result<Meme, MemeThingError>) -> Void) {
        CKService.shared.read(reference: reference) { (result: Result<Meme, MemeThingError>) in
            switch result {
            case .success(let meme):
                // Return the success
                return completion(.success(meme))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Update a meme with a new caption
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
    
    // Update a meme with a winning caption
    func setWinningCaption(to caption: Caption, for meme: Meme, completion: @escaping resultHandler) {
        // Update the meme with the with the index of the winning caption
        meme.winningCaptionIndex = meme.captions?.firstIndex(of: caption.reference)
        
        CKService.shared.update(object: meme) { (result) in
            switch result {
            case .success(_):
                // Update the points of the author who wrote that caption
                // FIXME: - how do I do this??
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // MARK: - Notifications?
    
    // TODO: - subscribe to notifications for captions you created, in case you won
    
    // TODO: - receive a notification that your caption has won, update your points and update the game accordingly
    
    // TODO: - remove subscriptions to captions after receiving a response or when the game is over
}
