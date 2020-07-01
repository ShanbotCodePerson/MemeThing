//
//  Caption.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/30/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// MARK: - String Constants

struct CaptionStrings {
    static let recordType = "Caption"
    fileprivate static let textKey = "text"
    fileprivate static let authorIDKey = "authorID"
    static let memeIDKey = "memeID"
    static let gameIDKey = "gameID"
    static let recordIDKey = "recordID"
}

class Caption {
    
    // MARK: - Properties
    
    let text: String
    let authorID: String
    let memeID: String
    let gameID: String
    let recordID: String
    
    // MARK: - Initializers
    
    init(text: String,
         authorID: String,
         memeID: String,
         gameID: String,
         recordID: String = UUID().uuidString) {
        
        self.text = text
        self.authorID = authorID
        self.memeID = memeID
        self.gameID = gameID
        self.recordID = recordID
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let text = dictionary[CaptionStrings.textKey] as? String,
            let authorID = dictionary[CaptionStrings.authorIDKey] as? String,
            let memeID = dictionary[CaptionStrings.memeIDKey] as? String,
            let gameID = dictionary[CaptionStrings.gameIDKey] as? String,
            let recordID = dictionary[CaptionStrings.recordIDKey] as? String
            else { return nil }
        
        self.init(text: text, authorID: authorID, memeID: memeID, gameID: gameID, recordID: recordID)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [CaptionStrings.textKey : text,
         CaptionStrings.authorIDKey : authorID,
         CaptionStrings.memeIDKey : memeID,
         CaptionStrings.gameIDKey : gameID,
         CaptionStrings.recordIDKey : recordID]
    }
}
