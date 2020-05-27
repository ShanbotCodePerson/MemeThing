//
//  CKService.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit

class CKService: CKServicing {
    static let shared = CKService()
}

// Define the characteristics of a generic type that can be saved to CloudKit
protocol CKCompatible {
    var ckRecord: CKRecord { get }
    var recordID: CKRecord.ID { get set }
    static var recordType: CKRecord.RecordType { get }
    init?(ckRecord: CKRecord)
}

// Define the basic CRUD functions for accessing the cloud
protocol CKServicing {
    typealias SingleItemHandler<T> = (Result<T, MemeThingError>) -> Void
    typealias ArrayHandler<T> = (Result<[T], MemeThingError>) -> Void
    
    var publicDB: CKDatabase { get }
    
    func create<T: CKCompatible> (object: T, completion: @escaping SingleItemHandler<T>)
    func read<T: CKCompatible> (predicate: NSCompoundPredicate, completion: @escaping ArrayHandler<T>)
    func update<T: CKCompatible> (object: T, completion: @escaping SingleItemHandler<T>)
    func delete<T: CKCompatible> (object: T, completion: @escaping SingleItemHandler<Bool>)
}

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
        
        // Fetch the data from the cloud
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            // Handle any errors
            if let error = error { return completion(.failure(.ckError(error))) }
            
            // Unwrap the data
            guard let objects = records?.compactMap({ T(ckRecord: $0) }) else { return completion(.failure(.couldNotUnwrap)) }
            
            // Complete with the objects
            return completion(.success(objects))
        }
    }
    
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
