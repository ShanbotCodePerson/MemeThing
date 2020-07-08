//
//  ComplaintController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/30/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage
import UIKit.UIImage

class ComplaintController {
    
    // MARK: - Properties
    
    static let db = Firestore.firestore()
    static let storage = Storage.storage()
    
    // MARK: - CRUD Methods
    
    // Save a complaint to the cloud
    static func createComplaint(with content: String, image: UIImage?, caption: String? = nil, completion: @escaping resultCompletion) {
        
        // Create the complaint
        let complaint = Complaint(content: content, caption: caption)
        
        // Save the image using the complaint's record id
        if let image = image { save(image, id: complaint.recordID) }
        
        // Save the complaint to the cloud
        db.collection(ComplaintStrings.recordType)
            .addDocument(data: complaint.asDictionary()) { (error) in
                
                if let error = error {
                    // Print and return the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    return completion(.failure(.fsError(error)))
                }
                
                return completion(.success(true))
        }
    }
    
    // A helper function to save the offending image to the cloud
    private static func save(_ image: UIImage, id: String) {
        // Convert the image to data
        guard let data = image.compressTo(0.5) else { return }
        
        // Create a name for the file in the cloud using the user's id
        let imageRef = storage.reference().child("reportedImages/\(id).jpg")
        
        // Save the data to the cloud
        imageRef.putData(data, metadata: nil) { (_, error) in
            if let error = error { print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)") }
        }
    }
}
