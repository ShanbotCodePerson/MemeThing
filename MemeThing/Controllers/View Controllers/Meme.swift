//
//  Meme.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/29/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit
import UIKit.UIImage

// MARK: - String Constants

struct MemeStrings {
    fileprivate static let recordType = "User"
    fileprivate static let photoKey = "photo"
    fileprivate static let authorKey = "author"
    fileprivate static let captionsKey = "captions"
    fileprivate static let winningCaptionIndexKey = "winningCaptionIndexKey"
    static let gameIDKey = "gameID"
}

class Meme: CKCompatible, CKPhotoAsset {

    // MARK: - Properties
    
    // Meme properties
    var photo: UIImage?
    var author: CKRecord.Reference
    var captions: [CKRecord.Reference]?
    var winningCaptionIndex: Int?
    
    // CloudKit Properties
    var gameID: CKRecord.ID
    static var recordType: CKRecord.RecordType { MemeStrings.recordType }
    var ckRecord: CKRecord { createCKRecord() }
    var recordID: CKRecord.ID
    
    // MARK: - Initializer
    
    init(photo: UIImage, author: CKRecord.Reference, captions: [CKRecord.Reference]? = nil, winningCaptionIndex: Int? = nil, gameID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString), recordID:  CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        // FIXME: - gameID needs to not have a default - comes from game
        self.photo = photo
        self.author = author
        self.captions = captions
        self.winningCaptionIndex = winningCaptionIndex
        self.gameID = gameID
        self.recordID = recordID
    }
    
    // MARK: - Convert from CKRecord
    
    required convenience init?(ckRecord: CKRecord) {
        guard let author = ckRecord[MemeStrings.authorKey] as? CKRecord.Reference,
            let gameID = ckRecord[MemeStrings.gameIDKey] as? CKRecord.ID
            else { return nil }
        let captions = ckRecord[MemeStrings.captionsKey] as? [CKRecord.Reference]
        let winningCaptionIndex = ckRecord[MemeStrings.winningCaptionIndexKey] as? Int
        
        var photo: UIImage?
        if let photoAsset = ckRecord[MemeStrings.photoKey] as? CKAsset {
            do {
                let data = try Data(contentsOf: photoAsset.fileURL!)
                photo = UIImage(data: data)
            } catch {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
        guard let unwrappedPhoto = photo else { return nil }
        
        self.init(photo: unwrappedPhoto, author: author, captions: captions, winningCaptionIndex: winningCaptionIndex, gameID: gameID, recordID: ckRecord.recordID)
    }
    
    // MARK: - Convert to CKRecord
    
    func createCKRecord() -> CKRecord {
        let record = CKRecord(recordType: MemeStrings.recordType, recordID: recordID)
        
        if let photoAsset = photoAsset { record.setValue(photoAsset, forKey: MemeStrings.photoKey) }
        record.setValue(author, forKey: MemeStrings.authorKey)
        if let captions = captions { record.setValue(captions, forKey: MemeStrings.captionsKey) }
        if let winningCaptionIndex = winningCaptionIndex { record.setValue(winningCaptionIndex, forKey: MemeStrings.winningCaptionIndexKey) }
        record.setValue(gameID, forKey: MemeStrings.gameIDKey)
        
        return record
    }
}
