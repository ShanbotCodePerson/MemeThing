//
//  CKService.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit
import UIKit.UIImage

class CKService: CKServicing {
    static let shared = CKService()
}

// MARK: - CKCompatible Protocol

// Define the characteristics of a generic type that can be saved to CloudKit
protocol CKCompatible {
    static var recordType: CKRecord.RecordType { get }
    var ckRecord: CKRecord { get }
    var recordID: CKRecord.ID { get set }
    init?(ckRecord: CKRecord)
}

// MARK: - CKServicing Protocol

// Define the basic CRUD functions for accessing the cloud
protocol CKServicing {
    typealias SingleItemHandler<T> = (Result<T, MemeThingError>) -> Void
    typealias ArrayHandler<T> = (Result<[T], MemeThingError>) -> Void
    
    var publicDB: CKDatabase { get }
    
    func create<T: CKCompatible> (object: T, completion: @escaping SingleItemHandler<T>)
    func read<T: CKCompatible> (predicate: NSCompoundPredicate, completion: @escaping ArrayHandler<T>)
    func read<T: CKCompatible> (reference: CKRecord.Reference, completion: @escaping SingleItemHandler<T>)
    func read<T: CKCompatible> (recordID: CKRecord.ID, completion: @escaping SingleItemHandler<T>)
    func update<T: CKCompatible> (object: T, completion: @escaping SingleItemHandler<T>)
    func delete<T: CKCompatible> (object: T, completion: @escaping SingleItemHandler<Bool>)
}

// MARK: - CKServicing Implementation

// Provide default implementations of the CRUD functions

extension CKServicing {
    var publicDB: CKDatabase { CKContainer.default().publicCloudDatabase }
    
    func create<T: CKCompatible> (object: T, completion: @escaping SingleItemHandler<T>) {
        // Convert the item to a CKRecord
        let record = object.ckRecord
        
        // Save the record to the cloud
        publicDB.save(record) { (record, error) in
            // Handle any errors
            if let error = error { return completion(.failure(.ckError(error))) }
            
            // Unwrap the data
            guard let record = record, let savedObject = T(ckRecord: record) else { return completion(.failure(.couldNotUnwrap)) }
            
            // Complete with the object
            return completion(.success(savedObject))
        }
    }
    
    func read<T: CKCompatible> (predicate: NSCompoundPredicate, completion: @escaping ArrayHandler<T>) {
        // Form the query based on the predicate
        let query = CKQuery(recordType: T.recordType, predicate: predicate)
//        print("got here to \(#function) and query is \(query)")
        
        // Fetch the data from the cloud
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            // Handle any errors
            if let error = error { return completion(.failure(.ckError(error))) }
//            print("inside completion and records are \(records)")
            // Unwrap the data
            guard let objects = records?.compactMap({ T(ckRecord: $0) }) else { return completion(.failure(.couldNotUnwrap)) }
//            print("unwrapped objects are \(objects)")
            
            // Complete with the objects
            return completion(.success(objects))
        }
    }
    
    func read<T: CKCompatible> (reference: CKRecord.Reference, completion: @escaping SingleItemHandler<T>) {
        // Fetch the data from the cloud
        publicDB.fetch(withRecordID: reference.recordID) { (record, error) in
            // Handle any errors
            if let error = error { return completion(.failure(.ckError(error))) }
            
            // Unwrap the data
            guard let record = record, let object = T(ckRecord: record)
                else { return completion(.failure(.couldNotUnwrap)) }
            
            // Complete with the objects
            return completion(.success(object))
        }
    }
    
    func read<T: CKCompatible> (recordID: CKRecord.ID, completion: @escaping SingleItemHandler<T>) {
        // Fetch the data from the cloud
        publicDB.fetch(withRecordID: recordID) { (record, error) in
            // Handle any errors
            if let error = error { return completion(.failure(.ckError(error))) }
            
            // Unwrap the data
            guard let record = record, let object = T(ckRecord: record)
                else { return completion(.failure(.couldNotUnwrap)) }
            
            // Complete with the objects
            return completion(.success(object))
        }
    }
    
    // TODO: - update multiple things (of different types) at once?
    func update<T: CKCompatible> (object: T, completion: @escaping SingleItemHandler<T>) {
        // Create the operation to save the updates to the object
        let operation = CKModifyRecordsOperation(recordsToSave: [object.ckRecord], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInteractive
        
        // Handle the completion of the operation
        operation.modifyRecordsCompletionBlock = { (records, _, error) in
            // Handle any errors
            if let error = error { return completion(.failure(.ckError(error))) }
            
            // Unwrap the data
            guard let object = records?.compactMap({ T(ckRecord: $0) }).first else { return completion(.failure(.couldNotUnwrap)) }
            
            // Complete with the object
            return completion(.success(object))
        }
        
        // Perform the operation to save the change to the cloud
        publicDB.add(operation)
    }
    
    func delete<T: CKCompatible> (object: T, completion: @escaping SingleItemHandler<Bool>) {
        // Create the operation to save the updates to the object
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [object.recordID])
        operation.qualityOfService = .userInteractive
        
        // Handle the completion of the operation
        operation.modifyRecordsCompletionBlock = { (_, recordIDs, error) in
            // Handle any errors
            if let error = error { return completion(.failure(.ckError(error))) }
            
            // Unwrap the data
            guard let recordIDs = recordIDs, recordIDs.count > 0 else { return completion(.failure(.couldNotUnwrap)) }
            
            // Complete with the object
            return completion(.success(true))
        }
        
        // Perform the operation to save the change to the cloud
        publicDB.add(operation)
    }
}

// MARK: - CKPhoto Protocol

protocol CKPhotoAsset where Self: CKCompatible {
    var photo: UIImage? { get set }
    var photoData: Data? { get }
    var photoAsset: CKAsset? { get }
}

// MARK: - CKPhoto Implementation

extension CKPhotoAsset {
    var photoData: Data? {
        guard let photo = photo else { return nil }
        return photo.jpegData(compressionQuality: 0.5)
    }
    
    var photoAsset: CKAsset? {
        guard let photoData = photoData else { return nil }
        let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileURL = directoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
        do {
            try photoData.write(to: fileURL)
        } catch {
            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
        }
        return CKAsset(fileURL: fileURL)
    }
}
