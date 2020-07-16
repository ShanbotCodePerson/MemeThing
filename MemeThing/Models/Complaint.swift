//
//  Complaint.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/30/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// MARK: - String Constants

struct ComplaintStrings {
    static let recordType = "Complaint"
    static let contentKey = "content"
    fileprivate static let captionKey = "caption"
    fileprivate static let recordIDKey = "recordID"
}

class Complaint {
    
    // MARK: - Properties
    
    let content: String
    let caption: String?
    let recordID: String
    
    // MARK: - Initializers
    
    init(content: String,
         caption: String?,
         recordID: String = UUID().uuidString) {
        
        self.content = content
        self.caption = caption
        self.recordID = recordID
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let content = dictionary[ComplaintStrings.contentKey] as? String,
            let recordID = dictionary[ComplaintStrings.recordIDKey] as? String
            else { return nil }
        let caption = dictionary[ComplaintStrings.captionKey] as? String
        
        self.init(content: content, caption: caption, recordID: recordID)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [ComplaintStrings.contentKey : content,
         ComplaintStrings.captionKey : caption as Any,
         ComplaintStrings.recordIDKey : recordID]
    }
}
