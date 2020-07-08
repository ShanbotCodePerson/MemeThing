//
//  MemeThing.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/31/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// MARK: - String Constants

struct FriendRequestStrings {
    static let recordType = "FriendRequest"
    static let fromIDKey = "fromID"
    static let fromNameKey = "fromName"
    static let toIDKey = "toID"
    static let toNameKey = "toName"
    static let statusKey = "status"
    static let recordIDKey = "recordID"
}

class FriendRequest {
    
    // MARK: - Properties
    
    let fromID: String
    let fromName: String
    let toID: String
    let toName: String
    var status: Status
    let recordID: String
    var documentID: String?
    
    enum Status: Int {
        case waiting
        case accepted
        case denied
        case removingFriend
    }
    
    // MARK: - Initializers
    
    init(fromID: String,
         fromName: String,
         toID: String,
         toName: String,
         status: Status = .waiting,
         recordID: String = UUID().uuidString,
         documentID: String? = nil) {
        
        self.fromID = fromID
        self.fromName = fromName
        self.toID = toID
        self.toName = toName
        self.status = status
        self.recordID = recordID
        self.documentID = documentID
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let fromID = dictionary[FriendRequestStrings.fromIDKey] as? String,
            let fromName = dictionary[FriendRequestStrings.fromNameKey] as? String,
            let toID = dictionary[FriendRequestStrings.toIDKey] as? String,
            let toName = dictionary[FriendRequestStrings.toNameKey] as? String,
            let statusRawValue = dictionary[FriendRequestStrings.statusKey] as? Int,
            let status = Status(rawValue: statusRawValue),
            let recordID = dictionary[FriendRequestStrings.recordIDKey] as? String
            else { return nil }
        
        self.init(fromID: fromID,
                  fromName: fromName,
                  toID: toID,
                  toName: toName,
                  status: status,
                  recordID: recordID)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [FriendRequestStrings.fromIDKey : fromID,
         FriendRequestStrings.fromNameKey : fromName,
         FriendRequestStrings.toIDKey : toID,
         FriendRequestStrings.toNameKey : toName,
         FriendRequestStrings.statusKey : status.rawValue,
         FriendRequestStrings.recordIDKey : recordID]
    }
}

// MARK: - Equatable

extension FriendRequest: Equatable {
    static func == (lhs: FriendRequest, rhs: FriendRequest) -> Bool {
        return lhs.recordID == rhs.recordID
    }
}
