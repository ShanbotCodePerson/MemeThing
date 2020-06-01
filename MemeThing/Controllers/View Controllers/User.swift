//
//  User.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit

// MARK: - String Constants

struct UserStrings {
    static let recordType = "User"
    static let usernameKey = "username"
    fileprivate static let passwordKey = "password"
    fileprivate static let screenNameKey = "screenName"
    fileprivate static let emailKey = "email"
    fileprivate static let pointsKey = "points"
    fileprivate static let friendsReferenceKey = "friendsReference"
    static let appleUserReferenceKey = "appleUserReference"
}

class User: CKCompatible {
    
    // MARK: - Properties
    
    // User properties
    let username: String
    var password: String
    var screenName: String
    var email: String
    var points: Int
    
    // CloudKit properties
    var friendsReferences: [CKRecord.Reference]
    let appleUserReference: CKRecord.Reference
    var reference: CKRecord.Reference { CKRecord.Reference(recordID: recordID, action: .none) }
    static var recordType: CKRecord.RecordType { UserStrings.recordType }
    var ckRecord: CKRecord { createCKRecord() }
    var recordID: CKRecord.ID
    
    // MARK: - Initializer
    
    init(username: String, password: String, screenName: String?, email: String, points: Int = 0, friendsReferences: [CKRecord.Reference] = [], appleUserReference: CKRecord.Reference, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        self.username = username
        self.password = password
        if let screenName = screenName {
            self.screenName = screenName
        } else {
            self.screenName = username
        }
        self.email = email
        self.points = points
        self.friendsReferences = friendsReferences
        self.appleUserReference = appleUserReference
        self.recordID = recordID
    }
    
    // MARK: - Convert from CKRecord
    
    required convenience init?(ckRecord: CKRecord) {
        guard let username = ckRecord[UserStrings.usernameKey] as? String,
            let password = ckRecord[UserStrings.passwordKey] as? String,
            let screenName = ckRecord[UserStrings.screenNameKey] as? String,
            let email = ckRecord[UserStrings.emailKey] as? String,
            let points = ckRecord[UserStrings.pointsKey] as? Int,
            let friendsReferences = ckRecord[UserStrings.friendsReferenceKey] as? [CKRecord.Reference],
            let appleUserReference = ckRecord[UserStrings.appleUserReferenceKey] as? CKRecord.Reference
            else { return nil }
        
        self.init(username: username, password: password, screenName: screenName, email: email, points: points, friendsReferences: friendsReferences, appleUserReference: appleUserReference, recordID: ckRecord.recordID)
    }
    
    // MARK: - Convert to CKRecord
    
    func createCKRecord() -> CKRecord {
        let record = CKRecord(recordType: UserStrings.recordType, recordID: recordID)
        
        record.setValuesForKeys([
            UserStrings.usernameKey : username,
            UserStrings.passwordKey : password,
            UserStrings.screenNameKey : screenName,
            UserStrings.emailKey : email,
            UserStrings.pointsKey : points,
            UserStrings.friendsReferenceKey : friendsReferences,
            UserStrings.appleUserReferenceKey : appleUserReference
        ])
        
        return record
    }
}
