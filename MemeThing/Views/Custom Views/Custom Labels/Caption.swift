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
    fileprivate static let recordType = "Caption"
    fileprivate static let textKey = "text"
    fileprivate static let authorKey = "author"
    fileprivate static let memeKey = "meme"
}

class Caption: CKCompatible {

    // MARK: - Properties
    
    // Caption properties
    let text: String
    let author: CKRecord.Reference
    let meme: CKRecord.Reference
    
    // CloudKit properties
    var reference: CKRecord.Reference { CKRecord.Reference(recordID: recordID, action: .deleteSelf) }
    static var recordType: CKRecord.RecordType { CaptionStrings.recordType }
    var ckRecord: CKRecord { createCKRecord() }
    var recordID: CKRecord.ID
    
    // MARK: - Initializer
    
    init(text: String, author: CKRecord.Reference, meme: CKRecord.Reference, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        self.text = text
        self.author = author
        self.meme = meme
        self.recordID = recordID
    }
    
    // MARK: - Convert from CKRecord
    
    required convenience init?(ckRecord: CKRecord) {
        guard let text = ckRecord[CaptionStrings.textKey] as? String,
            let author = ckRecord[CaptionStrings.authorKey] as? CKRecord.Reference,
            let meme = ckRecord[CaptionStrings.memeKey] as? CKRecord.Reference
            else { return nil }
        
        self.init(text: text, author: author, meme: meme, recordID: ckRecord.recordID)
    }
    
    // MARK: - Convert to CKRecord
    
    func createCKRecord() -> CKRecord {
        let record = CKRecord(recordType: CaptionStrings.recordType, recordID: recordID)
        
        record.setValuesForKeys([
            CaptionStrings.textKey : text,
            CaptionStrings.authorKey : author,
            CaptionStrings.memeKey : meme
        ])
        
        return record
    }
}
