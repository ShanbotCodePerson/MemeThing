//
//  Meme.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/29/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import UIKit.UIImage

// MARK: - String Constants

struct MemeStrings {
    static let recordType = "Meme"
    fileprivate static let authorIDKey = "authorID"
    fileprivate static let winningCaptionIDKey = "winningCaptionID"
    static let gameIDKey = "gameID"
    static let recordIDKey = "recordID"
}

class Meme {
    
    // MARK: - Properties
    
    var image: UIImage?
    let authorID: String
    var winningCaptionID: String?
    var gameID: String
    let recordID: String
    var documentID: String?
    
    // MARK: - Initializers
    
    init(image: UIImage?,
         authorID: String,
         winningCaptionID: String? = nil,
         gameID: String,
         recordID: String = UUID().uuidString) {
        
        self.image = image
        self.authorID = authorID
        self.winningCaptionID = winningCaptionID
        self.gameID = gameID
        self.recordID = recordID
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let authorID = dictionary[MemeStrings.authorIDKey] as? String,
            let gameID = dictionary[MemeStrings.gameIDKey] as? String,
            let recordID = dictionary[MemeStrings.recordIDKey] as? String
            else { return nil }
        let winningCaptionID = dictionary[MemeStrings.winningCaptionIDKey] as? String
        
        self.init(image: nil,
                  authorID: authorID,
                  winningCaptionID: winningCaptionID,
                  gameID: gameID,
                  recordID: recordID)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [MemeStrings.authorIDKey : authorID,
         MemeStrings.winningCaptionIDKey : winningCaptionID as Any,
         MemeStrings.gameIDKey : gameID,
         MemeStrings.recordIDKey : recordID]
    }
}

// MARK: - Equatable

extension Meme: Equatable {
    static func == (lhs: Meme, rhs: Meme) -> Bool {
        return lhs.recordID == rhs.recordID
    }
}
