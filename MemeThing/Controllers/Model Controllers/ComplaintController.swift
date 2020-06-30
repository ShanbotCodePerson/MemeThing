//
//  ComplaintController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/30/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit
import UIKit.UIImage

class ComplaintController {
    
    // Save a complaint to the cloud
    static func createComplaint(with content: String, photo: UIImage?, caption: String? = nil, completion: @escaping (Result<Bool, MemeThingError>) -> Void) {
        
        // Create the complaint
        let complaint = Complaint(content: content, photo: photo, caption: caption)
        
        // Save the complaint to the cloud
        CKService.shared.create(object: complaint) { (result) in
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
    
}
