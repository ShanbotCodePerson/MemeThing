//
//  MemeThing.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/31/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit

// MARK: - String Constants

struct FriendRequestStrings {
    static let recordType = "FriendRequest"
    static let fromKey = "from"
    static let toKey = "to"
    static let acceptedKey = "accepted"
}

class FriendRequest: CKCompatible {
    
    // MARK: - Properties
    
    // FriendRequest properties
    let from: String
    let to: String
    var accepted: Bool
    
    // CloudKit properties
    static var recordType: CKRecord.RecordType { UserStrings.recordType }
    var ckRecord: CKRecord { createCKRecord() }
    var recordID: CKRecord.ID
    
    // MARK: - Initializer
    
    init(from: String, to: String, accepted: Bool = false, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        self.from = from
        self.to = to
        self.accepted = accepted
        self.recordID = recordID
    }
    
    // MARK: - Convert from CKRecord
    
    required convenience init?(ckRecord: CKRecord) {
        guard let from = ckRecord[FriendRequestStrings.fromKey] as? String,
            let to = ckRecord[FriendRequestStrings.toKey] as? String,
            let accepted = ckRecord[FriendRequestStrings.acceptedKey] as? Bool
            else { return nil }
        
        self.init(from: from, to: to, accepted: accepted, recordID: ckRecord.recordID)
    }
    
    // MARK: - Convert to CKRecord
    
    func createCKRecord() -> CKRecord {
        let record = CKRecord(recordType: FriendRequestStrings.recordType, recordID: recordID)
        
        record.setValuesForKeys([
            FriendRequestStrings.fromKey : from,
            FriendRequestStrings.toKey : to,
            FriendRequestStrings.acceptedKey : accepted
        ])
        
        return record
    }
}
