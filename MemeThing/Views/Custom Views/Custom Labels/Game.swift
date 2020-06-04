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
    static let recordType = "Game"
    static let playersKey = "players"
    static let playersStatusKey = "playersStatus"
    fileprivate static let leadPlayerKey = "leadPlayer"
    fileprivate static let memesKey = "memes"
    fileprivate static let pointsToWinKey = "pointsLimit"
    fileprivate static let gameStatusKey = "gameStatus"
}

class Game: CKCompatible {
    
    // MARK: - Properties
    
    // Game properties
    var players: [CKRecord.Reference]
    var playersStatus: [PlayerStatus]
    var leadPlayer: CKRecord.Reference
    var memes: [CKRecord.Reference]? // FIXME: -should this be a reference or list of meme objects?
    let pointsToWin: Int
    var gameStatus: GameStatus
    
    // CloudKit properties
    var reference: CKRecord.Reference { CKRecord.Reference(recordID: recordID, action: .deleteSelf) }
    static var recordType: CKRecord.RecordType { GameStrings.recordType }
    var ckRecord: CKRecord { createCKRecord() }
    var recordID: CKRecord.ID
    
    // Player Status
    enum PlayerStatus: Int {
        case waiting
        case accepted
        case denied
        case quit
    }
    
    // Game Status
    enum GameStatus: Int {
        case waitingForPlayers
        case waitingForDrawing
        case waitingForCaptions
        case waitingForResult
        case waitingForNextRound
    }
    
    // MARK: - Initializer
    
    init(players: [CKRecord.Reference], playersStatus: [PlayerStatus]? = nil, leadPlayer: CKRecord.Reference, memes: [CKRecord.Reference]? = nil, pointsToWin: Int = 3, gameStatus: GameStatus = .waitingForPlayers, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        self.players = players
        if let playersStatus = playersStatus { self.playersStatus = playersStatus }
        else {
            // By default, the initial status of all players is waiting, except for the lead player (who starts off at the first index)
            self.playersStatus = Array(repeating: .waiting, count: players.count - 1)
            self.playersStatus.insert(.accepted, at: 0)
        }
        self.leadPlayer = leadPlayer
        self.memes = memes
        self.pointsToWin = pointsToWin
        self.gameStatus = gameStatus
        self.recordID = recordID
    }
    
    // MARK: - Convert from CKRecord
    
    required convenience init?(ckRecord: CKRecord) {
        guard let players = ckRecord[GameStrings.playersKey] as? [CKRecord.Reference],
            let playersStatusRawValues = ckRecord[GameStrings.playersStatusKey] as? [Int],
            let leadPlayer = ckRecord[GameStrings.leadPlayerKey] as? CKRecord.Reference,
            let pointsToWin = ckRecord[GameStrings.pointsToWinKey] as? Int,
            let gameStatusRawValue = ckRecord[GameStrings.gameStatusKey] as? Int,
            let gameStatus = GameStatus(rawValue: gameStatusRawValue)
            else { return nil }
        let memes = ckRecord[GameStrings.memesKey] as? [CKRecord.Reference]
        let playersStatus = playersStatusRawValues.compactMap({ PlayerStatus(rawValue: $0) })
        
        self.init(players: players, playersStatus: playersStatus, leadPlayer: leadPlayer, memes: memes, pointsToWin: pointsToWin, gameStatus: gameStatus, recordID: ckRecord.recordID)
    }
    
    // MARK: - Convert to CKRecord
    
    func createCKRecord() -> CKRecord {
        let record = CKRecord(recordType: GameStrings.recordType, recordID: recordID)
        
        record.setValuesForKeys([
            GameStrings.playersKey : players,
            GameStrings.playersStatusKey : playersStatus.compactMap({ $0.rawValue }),
            GameStrings.leadPlayerKey : leadPlayer,
            GameStrings.pointsToWinKey : pointsToWin,
            GameStrings.gameStatusKey : gameStatus.rawValue
        ])
        if let memes = memes {
            record.setValue(memes, forKey: GameStrings.memesKey)
        }
        
        return record
    }
}

// MARK: - Equatable

extension Game: Equatable {
    
    static func == (lhs: Game, rhs: Game) -> Bool {
        return lhs.recordID == rhs.recordID
    }
}
