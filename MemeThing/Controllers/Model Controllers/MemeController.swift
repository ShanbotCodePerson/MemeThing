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
    typealias resultHandlerWithObject = (Result<Meme, MemeThingError>) -> Void
    
    // MARK: - CRUD Methods
    
    // Create a new meme
    func createMeme(in game: Game, with photo: UIImage, by author: User, completion: @escaping resultHandlerWithObject) {
        // Create the meme
        let meme = Meme(photo: photo, author: author.reference, game: game.reference)
        
        // Save it to the cloud
        CKService.shared.create(object: meme) { (result) in
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
    
    // Read (fetch) a meme from a reference
    func fetchMeme(from reference: CKRecord.Reference, completion: @escaping resultHandlerWithObject) {
        // Fetch the data from the cloud
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
    
    // Read (fetch) a list of captions for a meme
    func fetchCaptions(for meme: Meme, completion: @escaping (Result<[Caption], MemeThingError>) -> Void) {
        // Form the predicate to look for all captions that reference that meme
        let predicate = NSPredicate(format: "%K == %@", argumentArray: [CaptionStrings.memeKey, meme.reference.recordID])
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate])
//        print("got here to \(#function) and predicate is \(compoundPredicate)")
        
        // Fetch the data from the cloud
        CKService.shared.read(predicate: compoundPredicate) { (result: Result<[Caption], MemeThingError>) in
            switch result {
            case .success(let captions):
                // Return the success
                return completion(.success(captions))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Read (fetch) the winning caption for a meme
    func fetchWinningCaption(for meme: Meme, completion: @escaping (Result<Caption, MemeThingError>) -> Void) {
        // Get the recordID of the winning caption from the meme
        guard let index = meme.winningCaptionIndex,
            let recordID = meme.captions?[index].recordID
            else { return completion(.failure(.unknownError)) }
        
        // Fetch the data from the cloud
        CKService.shared.read(recordID: recordID) { (result: Result<Caption, MemeThingError>) in
            switch result {
            case .success(let caption):
                // Return the success
                return completion(.success(caption))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Update a meme
    private func update(_ meme: Meme, completion: @escaping resultHandler) {
        // Save the updated meme to the cloud
        CKService.shared.update(object: meme) { (result) in
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
    
    // Update a meme with a new caption
    func createCaption(for meme: Meme, by author: User, with text: String, in game: Game, completion: @escaping resultHandler) {
        // Create the caption
        let caption = Caption(text: text, author: author.reference, meme: meme.reference, game: game.reference)
        
        // Save it to the cloud
        CKService.shared.create(object: caption) { [weak self] (result) in
            switch result {
            case .success(let caption):
                // Add the caption to the list of captions on the meme
                if meme.captions != nil {
                    meme.captions!.append(caption.reference)
                } else {
                    meme.captions = [caption.reference]
                }
                
                // FIXME: - refactor this elsewhere
                // Save the change to the meme
                self?.update(meme) { (result) in
                    switch result {
                    case .success(_):
                        print("got here to \(#function) and meme has \(String(describing: meme.captions?.count)) captions and id \(meme.reference.recordID.recordName)")
                        // Return the success
                        return completion(.success(true))
                    case .failure(let error):
                        // Print and return the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        return completion(.failure(error))
                    }
                }
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Update a meme with a winning caption
    func setWinningCaption(to caption: Caption, for meme: Meme, completion: @escaping resultHandler) {
        // Update the caption's status
        caption.didWin = true
        
        // Save the change to the cloud
        CKService.shared.update(object: caption) { [weak self] (result) in
            switch result {
            case .success(let caption):
                // Update the meme with the with the index of the winning caption
                meme.winningCaptionIndex = meme.captions?.firstIndex(of: caption.reference)
                self?.update(meme, completion: { (result) in
                    switch result {
                    case .success(_):
                        // Return the success
                        return completion(.success(true))
                    case .failure(let error):
                        // Print and return the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        return completion(.failure(error))
                    }
                })
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
}
