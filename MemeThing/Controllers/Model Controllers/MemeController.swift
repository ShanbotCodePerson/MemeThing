//
//  MemeController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/3/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage
import UIKit.UIImage

class MemeController {
    
    // MARK: - Singleton
    
    static let shared = MemeController()
    
    // MARK: - Properties
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    // MARK: - CRUD Methods
    
    // Create a new meme
    func createMeme(in game: Game, with image: UIImage, by author: User, completion: @escaping resultCompletionWith<Meme>) {
        
        // Create the meme
        let meme = Meme(image: image, authorID: author.recordID, gameID: game.recordID)
        
        let group = DispatchGroup()
        
        // Save the meme's image to the cloud storage
        group.enter()
        save(image, id: meme.recordID) { (result) in
            switch result {
            case .success(_):
                group.leave()
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
        
        // Save the meme to the cloud
        group.enter()
        let reference: DocumentReference = db.collection(MemeStrings.recordType).addDocument(data: meme.asDictionary()) { (error) in
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.fsError(error)))
            }
            group.leave()
        }
        
        // Return the success
        group.notify(queue: .main) {
            meme.documentID = reference.documentID
            return completion(.success(meme))
        }
    }
    
    // Save a meme's image
    private func save(_ image: UIImage, id: String, completion: @escaping resultCompletion) {
        // Convert the image to data
        guard let data = image.compressTo(1) else { return completion(.failure(.badPhotoFile)) }
        
        // Create a name for the file in the cloud using the user's id
        let photoRef = storage.reference().child("memes/\(id).jpg")
        
        // Save the data to the cloud
        photoRef.putData(data, metadata: nil) { (metadata, error) in
            
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.fsError(error)))
            }
            
            return completion(.success(true))
        }
    }
    
    // Read (fetch) a meme's image
    func getImage(for recordID: String, completion: @escaping resultCompletionWith<UIImage>) {
        // Get the reference to the profile photo
        let photoRef = storage.reference().child("memes/\(recordID).jpg")
        
        // Download the photo from the cloud
        photoRef.getData(maxSize: Int64(1.2 * 1024 * 1024)) { (data, error) in
            if let error = error {
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(.fsError(error)))
            }
            
            // Convert the data to an image and return it
            guard let data = data,
                let image = UIImage(data: data)
                else { return completion(.failure(.couldNotUnwrap)) }
            return completion(.success(image))
        }
    }
    
    // Read (fetch) a meme from a recordID
    func fetchMeme(from recordID: String, completion: @escaping resultCompletionWith<Meme>) {
        // Fetch the data from the cloud
        db.collection(MemeStrings.recordType)
            .whereField(MemeStrings.recordIDKey, isEqualTo: recordID)
            .getDocuments { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let document = results?.documents.first,
                    let meme = Meme(dictionary: document.data())
                    else { return completion(.failure(.couldNotUnwrap)) }
                meme.documentID = document.documentID
                
                // Fetch the meme's image
                self?.getImage(for: meme.recordID) { (result) in
                    switch result {
                    case .success(let image):
                        // Set the meme's image
                        meme.image = image
                        
                        // Return the success
                        return completion(.success(meme))
                    case .failure(let error):
                        // Print and return the error
                        // TODO: - use some default image in case it wasn't fetched correctly
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        return completion(.failure(error))
                    }
                }
        }
    }
    
    // Read (fetch) a list of captions for a meme
    func fetchCaptions(for meme: Meme, expectedNumber: Int, firstTry: Bool = true, completion: @escaping resultCompletionWith<[Caption]>) {
        // Fetch all the captions referencing the meme
        db.collection(CaptionStrings.recordType)
            .whereField(CaptionStrings.memeIDKey, isEqualTo: meme.recordID)
            .getDocuments { [weak self] (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let documents = results?.documents
                    else { return completion(.failure(.couldNotUnwrap)) }
                let captions = documents.compactMap { Caption(dictionary: $0.data()) }
                
                // If the captions aren't in the cloud on the first try, wait a second then try to fetch them again
                if firstTry && captions.count < expectedNumber {
                    sleep(1)
                    self?.fetchCaptions(for: meme, expectedNumber: expectedNumber, firstTry: false, completion: completion)
                }
                    // Otherwise, return the success
                else { return completion(.success(captions)) }
        }
    }
    
    // Read (fetch) the winning caption for a meme
    func fetchWinningCaption(for meme: Meme, completion: @escaping (Result<Caption, MemeThingError>) -> Void) {
        guard let winningCaptionID = meme.winningCaptionID else { return completion(.failure(.unknownError)) }
        
        // Fetch the data from the cloud
        db.collection(CaptionStrings.recordType)
            .whereField(CaptionStrings.recordIDKey, isEqualTo: winningCaptionID)
            .getDocuments { (results, error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                // Unwrap the data
                guard let document = results?.documents.first,
                    let caption = Caption(dictionary: document.data())
                    else { return completion(.failure(.couldNotUnwrap)) }
                
                // Return the success
                return completion(.success(caption))
        }
    }
    
    // Update a meme
    private func saveChanges(to meme: Meme, completion: @escaping resultCompletion) {
        guard let documentID = meme.documentID else { return completion(.failure(.noData)) }
        
        // Save the updated meme to the cloud
        db.collection(MemeStrings.recordType)
            .document(documentID)
            .setData(meme.asDictionary()) { (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                return completion(.success(true))
        }
    }
    
    // Update a meme with a new caption
    func createCaption(for meme: Meme, by author: User, with text: String, in game: Game, completion: @escaping resultCompletion) {
        // Create the caption
        let caption = Caption(text: text, authorID: author.recordID, memeID: meme.recordID, gameID: game.recordID)
        
        // Save the caption to the cloud
        db.collection(CaptionStrings.recordType)
            .addDocument(data: caption.asDictionary()) { (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                return completion(.success(true))
        }
    }
    
    // Update a meme with a winning caption
    func setWinningCaption(to caption: Caption, for meme: Meme, completion: @escaping resultCompletion) {
        // Add the recordID of the winning caption to the meme
        meme.winningCaptionID = caption.recordID
        
        // Save the updated meme to the cloud
        saveChanges(to: meme) { (result) in
            switch result {
            case .success(_):
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // TODO: - Delete all memes associated with a game when the game is over
    
    // TODO: - Delete all captions associated with a game when the game is over
}
