//
//  Caption.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/30/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit

// MARK: - String Constants

struct CaptionStrings {
    static let recordType = "Caption"
    fileprivate static let textKey = "text"
    fileprivate static let authorKey = "author"
    static let memeKey = "meme"
    fileprivate static let didWinKey = "didWin"
}

class Caption: CKCompatible {

    // MARK: - Properties
    
    // Caption properties
    let text: String
    let author: CKRecord.Reference
    let meme: CKRecord.Reference
    var didWin: Bool
    
    // CloudKit properties
    var reference: CKRecord.Reference { CKRecord.Reference(recordID: recordID, action: .deleteSelf) }
    static var recordType: CKRecord.RecordType { CaptionStrings.recordType }
    var ckRecord: CKRecord { createCKRecord() }
    var recordID: CKRecord.ID
    
    // MARK: - Initializer
    
    init(text: String, author: CKRecord.Reference, meme: CKRecord.Reference, didWin: Bool = false, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        self.text = text
        self.author = author
        self.meme = meme
        self.didWin = didWin
        self.recordID = recordID
    }
    
    // MARK: - Convert from CKRecord
    
    required convenience init?(ckRecord: CKRecord) {
        guard let text = ckRecord[CaptionStrings.textKey] as? String,
            let author = ckRecord[CaptionStrings.authorKey] as? CKRecord.Reference,
            let meme = ckRecord[CaptionStrings.memeKey] as? CKRecord.Reference,
            let didWin = ckRecord[CaptionStrings.didWinKey] as? Bool
            else { return nil }
        
        self.init(text: text, author: author, meme: meme, didWin: didWin, recordID: ckRecord.recordID)
    }
    
    // MARK: - Convert to CKRecord
    
    func createCKRecord() -> CKRecord {
        let record = CKRecord(recordType: CaptionStrings.recordType, recordID: recordID)
        
        record.setValuesForKeys([
            CaptionStrings.textKey : text,
            CaptionStrings.authorKey : author,
            CaptionStrings.memeKey : meme,
            CaptionStrings.didWinKey : didWin
        ])
        
        return record
    }
}
