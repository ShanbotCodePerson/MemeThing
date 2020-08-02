//
//  User.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import UIKit.UIImage

// MARK: - String Constants

struct UserStrings {
    static let recordType = "User"
    static let emailKey = "email"
    fileprivate static let screenNameKey = "screenName"
    fileprivate static let profilePhotoURLKey = "profilePhotoURL"
    fileprivate static let pointsKey = "points"
    fileprivate static let blockedIDsKey = "blockedIDs"
    fileprivate static let friendIDsKey = "friendIDs"
    static let recordIDKey = "recordID"
}

class User {
    
    // MARK: - Properties
    
    let email: String
    var screenName: String
    var profilePhotoURL: String?
    var photo: UIImage?
    var points: Int
    var blockedIDs: [String]
    var friendIDs: [String]
    let recordID: String
    var documentID: String?
    
    // MARK: - Initializers
    
    init(email: String,
         screenName: String?,
         profilePhotoURL: String? = nil,
         points: Int = 0,
         blockedIDs: [String] = [],
         friendIDs: [String] = [],
         recordID: String = UUID().uuidString) {
        
        self.email = email
        self.screenName = (screenName ?? email.components(separatedBy: "@").first) ?? email
        self.profilePhotoURL = profilePhotoURL
        self.points = points
        self.blockedIDs = blockedIDs
        self.friendIDs = friendIDs
        self.recordID = recordID
        
        UserController.shared.fetchUsersProfilePhoto(user: self) { [weak self] (photo) in
            self?.photo = photo
            
            // Update the UI
            NotificationCenter.default.post(Notification(name: .friendsUpdate))
            NotificationCenter.default.post(Notification(name: .updateProfileView))
        }
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let email = dictionary[UserStrings.emailKey] as? String,
            let screenName = dictionary[UserStrings.screenNameKey] as? String,
            let points = dictionary[UserStrings.pointsKey] as? Int,
            let blockedIDs = dictionary[UserStrings.blockedIDsKey] as? [String],
            var friendIDs = dictionary[UserStrings.friendIDsKey] as? [String],
            let recordID = dictionary[UserStrings.recordIDKey] as? String
            else { return nil }
        let profilePhotoURL = dictionary[UserStrings.profilePhotoURLKey] as? String
        friendIDs = Array(Set(friendIDs))
        
        self.init(email: email,
                  screenName: screenName,
                  profilePhotoURL: profilePhotoURL,
                  points: points,
                  blockedIDs: blockedIDs,
                  friendIDs: friendIDs,
                  recordID: recordID)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [UserStrings.emailKey : email,
         UserStrings.screenNameKey : screenName,
         UserStrings.profilePhotoURLKey : profilePhotoURL as Any,
         UserStrings.pointsKey : points,
         UserStrings.blockedIDsKey : blockedIDs,
         UserStrings.friendIDsKey : friendIDs,
         UserStrings.recordIDKey : recordID
        ]
    }
}

// MARK: - Equatable

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.recordID == rhs.recordID
    }
}
