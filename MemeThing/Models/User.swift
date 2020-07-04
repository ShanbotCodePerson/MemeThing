//
//  User.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// MARK: - String Constants

struct UserStrings {
    static let recordType = "User"
    static let emailKey = "email"
    fileprivate static let screenNameKey = "screenName"
    fileprivate static let pointsKey = "points"
    fileprivate static let blockedIDsKey = "blockedIDs"
    fileprivate static let friendIDsKey = "friendIDs"
    static let recordIDKey = "recordID"
}

class User {
    
    // MARK: - Properties
    
    let email: String
    var screenName: String
    var points: Int
    var blockedIDs: [String]
    var friendIDs: [String]
    let recordID: String
    var documentID: String?
    
    // MARK: - Initializers
    
    init(email: String,
         screenName: String?,
         points: Int = 0,
         blockedIDs: [String] = [],
         friendIDs: [String] = [],
         recordID: String = UUID().uuidString) {
        
        self.email = email
        self.screenName = (screenName ?? email.components(separatedBy: "@").first) ?? email
        self.points = points
        self.blockedIDs = blockedIDs
        self.friendIDs = friendIDs
        self.recordID = recordID
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let email = dictionary[UserStrings.emailKey] as? String,
            let screenName = dictionary[UserStrings.screenNameKey] as? String,
            let points = dictionary[UserStrings.pointsKey] as? Int,
            let blockedIDs = dictionary[UserStrings.blockedIDsKey] as? [String],
            var friendIDs = dictionary[UserStrings.friendIDsKey] as? [String],
            let recordID = dictionary[UserStrings.recordIDKey] as? String
            else { return nil }
        friendIDs = Array(Set(friendIDs))
        
        self.init(email: email,
                  screenName: screenName,
                  points: points,
                  blockedIDs: blockedIDs,
                  friendIDs: friendIDs,
                  recordID: recordID)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [UserStrings.emailKey : email,
         UserStrings.screenNameKey : screenName,
         UserStrings.pointsKey : points,
         UserStrings.blockedIDsKey : blockedIDs,
         UserStrings.friendIDsKey : friendIDs,
         UserStrings.recordIDKey : recordID
        ]
    }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.recordID == rhs.recordID
    }
}
