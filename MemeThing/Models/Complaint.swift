//
//  Complaint.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/30/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit
import UIKit.UIImage

// MARK: - String Constants

struct ComplaintStrings {
    static let recordType = "Complaint"
    static let contentKey = "content"
    fileprivate static let photoAssetKey = "photoAsset"
    fileprivate static let captionKey = "caption"
}

class Complaint: CKCompatible, CKPhotoAsset {
    
    // MARK: - Properties
    
    // Complaint properties
    let content: String
    var photo: UIImage?
    let caption: String?
    
    // CK Properties
    var reference: CKRecord.Reference { CKRecord.Reference(recordID: recordID, action: .none) }
    static var recordType: CKRecord.RecordType { ComplaintStrings.recordType }
    var ckRecord: CKRecord { createCKRecord() }
    var recordID: CKRecord.ID
    
    // MARK: - Initializer
    
    init(content: String, photo: UIImage?, caption: String?, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        self.content = content
        self.photo = photo
        self.caption = caption
        self.recordID = recordID
    }
    
    // MARK: - Convert from CKRecord
    
    required convenience init?(ckRecord: CKRecord) {
        guard let content = ckRecord[ComplaintStrings.contentKey] as? String else { return nil }
        let caption = ckRecord[ComplaintStrings.captionKey] as? String
        
        var photo: UIImage?
        if let photoAsset = ckRecord[ComplaintStrings.photoAssetKey] as? CKAsset {
            do {
                let data = try Data(contentsOf: photoAsset.fileURL!)
                photo = UIImage(data: data)
            } catch {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
        guard let unwrappedPhoto = photo else { return nil }
        
        self.init(content: content, photo: unwrappedPhoto, caption: caption, recordID: ckRecord.recordID)
    }
    
    // MARK: - Convert to CKRecord

    func createCKRecord() -> CKRecord {
        let record = CKRecord(recordType: ComplaintStrings.recordType, recordID: recordID)
        
        record.setValue(content, forKey: ComplaintStrings.contentKey)
        if let photoAsset = photoAsset { record.setValue(photoAsset, forKey: ComplaintStrings.photoAssetKey) }
        if let caption = caption { record.setValue(caption, forKey: ComplaintStrings.captionKey) }
        
        return record
    }
}
