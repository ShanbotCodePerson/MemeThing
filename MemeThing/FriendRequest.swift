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
    static let fromReferenceKey = "fromReference"
    static let fromUsernameKey = "fromUsername"
    static let toReferenceKey = "toReference"
    static let toUsernameKey = "toUsername"
    static let statusKey = "status"
}

class FriendRequest: CKCompatible {
    
    // MARK: - Properties
    
    // FriendRequest properties
    let fromReference: CKRecord.Reference
    let fromUsername: String
    let toReference: CKRecord.Reference
    let toUsername: String
    var status: Status
    
    enum Status: Int {
        case waiting
        case accepted
        case denied
    }
    
    // FIXME: - use an enum for the response instead, so there's three possibilities
    
    // CloudKit properties
    static var recordType: CKRecord.RecordType { FriendRequestStrings.recordType }
    var ckRecord: CKRecord { createCKRecord() }
    var recordID: CKRecord.ID
    
    // MARK: - Initializer
    
    init(fromReference: CKRecord.Reference, fromUsername: String, toReference: CKRecord.Reference, toUsername: String, status: Status = .waiting, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        self.fromReference = fromReference
        self.fromUsername = fromUsername
        self.toReference = toReference
        self.toUsername = toUsername
        self.status = status
        self.recordID = recordID
    }
    
    // MARK: - Convert from CKRecord
    
    required convenience init?(ckRecord: CKRecord) {
        guard let fromReference = ckRecord[FriendRequestStrings.fromReferenceKey] as? CKRecord.Reference,
            let fromUsername = ckRecord[FriendRequestStrings.fromUsernameKey] as? String,
            let toReference = ckRecord[FriendRequestStrings.toReferenceKey] as? CKRecord.Reference,
            let toUsername = ckRecord[FriendRequestStrings.toUsernameKey] as? String,
            let statusRawValue = ckRecord[FriendRequestStrings.statusKey] as? Int,
            let status = Status(rawValue: statusRawValue)
            else { return nil }
        
        self.init(fromReference: fromReference, fromUsername: fromUsername, toReference: toReference, toUsername: toUsername, status: status, recordID: ckRecord.recordID)
    }
    
    // MARK: - Convert to CKRecord
    
    func createCKRecord() -> CKRecord {
        let record = CKRecord(recordType: FriendRequestStrings.recordType, recordID: recordID)
        
        record.setValuesForKeys([
            FriendRequestStrings.fromReferenceKey : fromReference,
            FriendRequestStrings.fromUsernameKey : fromUsername,
            FriendRequestStrings.toReferenceKey : toReference,
            FriendRequestStrings.toUsernameKey : toUsername,
            FriendRequestStrings.statusKey : status.rawValue
        ])
        
        return record
    }
}

// MARK: - Equatable

extension FriendRequest: Equatable {
    
    static func == (lhs: FriendRequest, rhs: FriendRequest) -> Bool {
        return lhs.recordID.recordName == rhs.recordID.recordName // TODO: - best way to do this?
    }
}
