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
    fileprivate static let playersNamesKey = "playersNames"
    fileprivate static let playersStatusKey = "playersStatus"
    fileprivate static let playersPointsKey = "playersPoints"
    fileprivate static let leadPlayerKey = "leadPlayer"
    fileprivate static let memesKey = "memes"
    fileprivate static let pointsToWinKey = "pointsLimit"
    fileprivate static let gameStatusKey = "gameStatus"
}

class Game: CKCompatible {
    
    // MARK: - Properties
    
    // Game properties
    var players: [CKRecord.Reference]
    var playersNames: [String]
    var playersStatus: [PlayerStatus]
    private var playersPoints: [Int]
    var leadPlayer: CKRecord.Reference
    var memes: [CKRecord.Reference]? // FIXME: -should this be a reference or list of meme objects?
    private let pointsToWin: Int
    var gameStatus: GameStatus
    
    // CloudKit properties
    var reference: CKRecord.Reference { CKRecord.Reference(recordID: recordID, action: .deleteSelf) }
    static var recordType: CKRecord.RecordType { GameStrings.recordType }
    var ckRecord: CKRecord { createCKRecord() }
    var recordID: CKRecord.ID
    
    // Player Status
    enum PlayerStatus: Int {
        case invited
        case accepted
        case denied
        case quit
        case sentDrawing
        case sentCaption
        
        var asString: String {
            switch self {
            case .accepted:
                return "In Game"
            case .denied:
                return "Declined Invitation"
            case .invited:
                return "Waiting for Response"
            case .quit:
                return "Quit Game"
            case .sentCaption:
                return "Submitted Caption"
            case .sentDrawing:
                return "Submitted Drawing"
            }
        }
    }
    
    // Game Status
    enum GameStatus: Int {
        case waitingForPlayers
        case waitingForDrawing
        case waitingForCaptions
        case waitingForResult
        case waitingForNextRound
        case gameOver
    }
    
    // MARK: - Helper Properties
    // Helper properties for easier interaction with the game object
    
    // A nicely formatted list of the names of the game participants, minus the current user
    var listOfPlayerNames: String {
        guard let currentUser = UserController.shared.currentUser else { return "ERROR" }
        return playersNames.filter({ $0 != currentUser.screenName }).joined(separator: ", ")
    }
    
    // The name of the lead player
    var leadPlayerName: String {
        guard let index = players.firstIndex(of: leadPlayer) else { return "" }
        return playersNames[index]
    }
    
    // A nicely formatted string to tell a given user what phase the game is currently in
    // TODO: - game phase string
    
    // TODO: - a function telling the view controller which view to go to, based on phase of game?
    
    // Calculate whether all players have responded to the game invitation
    var allPlayersResponded: Bool {
        // A player's status will only be "invited" if they haven't responded to the invitation yet
        return !playersStatus.contains(.invited)
    }
    
    // Calculate whether all players have submitted a caption
    var allCaptionsSubmitted: Bool {
        // Exclude any players who declined the invitation or quit the game
        let currentPlayers = playersStatus.filter { ($0 != .denied) && ($0 != .quit) }
        // Every other should have either sent a drawing (the lead player) or sent a caption (all other players)
        return Set(currentPlayers) == [.sentDrawing, .sentCaption]
    }
    
    // Figure out if a player has won the game yet
    var gameWinner: CKRecord.Reference? {
        // Check if the highest score has reached the points needed to win, and if so, return the reference to that player
        guard let highestScore = playersPoints.max(), highestScore == pointsToWin,
            let index = playersPoints.firstIndex(of: highestScore)
            else { return nil }
        return players[index]
    }
    
    // MARK: - Initializer
    
    init(players: [CKRecord.Reference],
         playersNames: [String],
         playersStatus: [PlayerStatus]? = nil,
         playersPoints: [Int]? = nil,
         leadPlayer: CKRecord.Reference,
         memes: [CKRecord.Reference]? = nil,
         pointsToWin: Int = 3,
         gameStatus: GameStatus = .waitingForPlayers,
         recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        
        self.players = players
        self.playersNames = playersNames
        if let playersStatus = playersStatus { self.playersStatus = playersStatus }
        else {
            // By default, the initial status of all players is waiting, except for the lead player (who starts off at the first index)
            self.playersStatus = Array(repeating: .invited, count: players.count - 1)
            self.playersStatus.insert(.accepted, at: 0)
        }
        if let playersPoints = playersPoints { self.playersPoints = playersPoints }
        else {
            // By default, all players start with zero points
            self.playersPoints = Array(repeating: 0, count: players.count)
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
            let playersNames = ckRecord[GameStrings.playersNamesKey] as? [String],
            let playersStatusRawValues = ckRecord[GameStrings.playersStatusKey] as? [Int],
            let playersPoints = ckRecord[GameStrings.playersPointsKey] as? [Int],
            let leadPlayer = ckRecord[GameStrings.leadPlayerKey] as? CKRecord.Reference,
            let pointsToWin = ckRecord[GameStrings.pointsToWinKey] as? Int,
            let gameStatusRawValue = ckRecord[GameStrings.gameStatusKey] as? Int,
            let gameStatus = GameStatus(rawValue: gameStatusRawValue)
            else { return nil }
        let memes = ckRecord[GameStrings.memesKey] as? [CKRecord.Reference]
        let playersStatus = playersStatusRawValues.compactMap({ PlayerStatus(rawValue: $0) })
        
        self.init(players: players, playersNames: playersNames, playersStatus: playersStatus, playersPoints: playersPoints, leadPlayer: leadPlayer, memes: memes, pointsToWin: pointsToWin, gameStatus: gameStatus, recordID: ckRecord.recordID)
    }
    
    // MARK: - Convert to CKRecord
    
    func createCKRecord() -> CKRecord {
        let record = CKRecord(recordType: GameStrings.recordType, recordID: recordID)
        
        record.setValuesForKeys([
            GameStrings.playersKey : players,
            GameStrings.playersNamesKey : playersNames,
            GameStrings.playersStatusKey : playersStatus.compactMap({ $0.rawValue }),
            GameStrings.playersPointsKey : playersPoints,
            GameStrings.leadPlayerKey : leadPlayer,
            GameStrings.pointsToWinKey : pointsToWin,
            GameStrings.gameStatusKey : gameStatus.rawValue
        ])
        if let memes = memes {
            record.setValue(memes, forKey: GameStrings.memesKey)
        }
        
        return record
    }
    
    // MARK: - Helper Methods
    
    // Quickly get a user's status
    func getStatus(of player: User) -> PlayerStatus {
        guard let index = players.firstIndex(of: player.reference) else { return .quit }
        return playersStatus[index]
    }
    
    // Quickly update a player's status
    func updateStatus(of player: User, to status: PlayerStatus) {
        guard let index = players.firstIndex(of: player.reference) else { return }
        playersStatus[index] = status
    }
    
    // Quickly update a player's points
    func updatePoints(of player: User) {
        guard let index = players.firstIndex(of: player.reference) else { return }
        playersPoints[index] += 1
    }
    
    // Reset the game for a new round
    func resetGame() {
        // Update the game's status
        gameStatus = .waitingForDrawing
        
        // Increment the lead player, looping back to the beginning if necessary
        guard var index = players.firstIndex(of: leadPlayer) else { return }
        index = (index + 1) % players.count
        leadPlayer = players[index]
        
        // Reset the status of all the active players
        for index in 0..<playersStatus.count {
            if playersStatus[index] == .sentCaption || playersStatus[index] == .sentDrawing {
                playersStatus[index] = .accepted
            }
        }
    }
}

// MARK: - Equatable

extension Game: Equatable {
    
    static func == (lhs: Game, rhs: Game) -> Bool {
        return lhs.recordID == rhs.recordID
    }
}
