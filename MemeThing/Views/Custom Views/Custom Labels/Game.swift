//
//  Game.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/30/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit

// MARK: - String Constants

struct GameStrings {
    fileprivate static let recordType = "Game"
    static let playersKey = "players"
    fileprivate static let leadPlayerKey = "leadPlayer"
    fileprivate static let memesKey = "memes"
    fileprivate static let pointsToWinKey = "pointsLimit"
}

class Game: CKCompatible {
    
    // MARK: - Properties
    
    // Game properties
    var players: [CKRecord.Reference]
    var leadPlayer: CKRecord.Reference
    var memes: [CKRecord.Reference] // FIXME: -should this be a reference or list of meme objects?
    let pointsToWin: Int
    
    // CloudKit properties
    var reference: CKRecord.Reference { CKRecord.Reference(recordID: recordID, action: .deleteSelf) }
    static var recordType: CKRecord.RecordType { GameStrings.recordType }
    var ckRecord: CKRecord { createCKRecord() }
    var recordID: CKRecord.ID
    
    // MARK: - Initializer
    
    init(players: [CKRecord.Reference], leadPlayer: CKRecord.Reference, memes: [CKRecord.Reference] = [], pointsToWin: Int = 3, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        self.players = players
        self.leadPlayer = leadPlayer
        self.memes = memes
        self.pointsToWin = pointsToWin
        self.recordID = recordID
    }
    
    // MARK: - Convert from CKRecord
    
    required convenience init?(ckRecord: CKRecord) {
        guard let players = ckRecord[GameStrings.playersKey] as? [CKRecord.Reference],
            let leadPlayer = ckRecord[GameStrings.leadPlayerKey] as? CKRecord.Reference,
            let memes = ckRecord[GameStrings.memesKey] as? [CKRecord.Reference],
            let pointsToWin = ckRecord[GameStrings.pointsToWinKey] as? Int
            else { return nil }
        
        self.init(players: players, leadPlayer: leadPlayer, memes: memes, pointsToWin: pointsToWin, recordID: ckRecord.recordID)
    }
    
    // MARK: - Convert to CKRecord
    
    func createCKRecord() -> CKRecord {
        let record = CKRecord(recordType: GameStrings.recordType, recordID: recordID)
        
        record.setValuesForKeys([
            GameStrings.playersKey : players,
            GameStrings.leadPlayerKey : leadPlayer,
            GameStrings.memesKey : memes,
            GameStrings.pointsToWinKey : pointsToWin
        ])
        
        return record
    }
}

// MARK: - Equatable

extension Game: Equatable {
    
    static func == (lhs: Game, rhs: Game) -> Bool {
        return lhs.recordID == rhs.recordID
    }
}
