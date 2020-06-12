//
//  FinishedGame+Convenience.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/11/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

extension FinishedGame {
    
    // MARK: - Convenience Initializers
    
    convenience init(players: [CKRecord.Reference], playersNames: [String], playersStatus: [Int], playersPoints: [Int], pointsToWin: Int, recordID: CKRecord.ID, context: NSManagedObjectContext = CoreDataStack.context) {
        self.init(context: context)
        
        self.playersIDs = players.map { $0.recordID.recordName }
        self.playersNames = playersNames
        self.playersStatusRawValues = playersStatus
        self.playersPoints = playersPoints
        self.pointsToWin = Int16(pointsToWin)
        self.recordID = recordID.recordName
    }
    
    convenience init(game: Game, context: NSManagedObjectContext = CoreDataStack.context) {
        self.init(context: context)
        
        self.playersIDs = game.players.map { $0.recordID.recordName }
        self.playersNames = game.playersNames
        self.playersStatusRawValues = game.playersStatus.map { $0.rawValue }
        self.playersPoints = game.playersPoints
        self.pointsToWin = Int16(game.pointsToWin)
        self.recordID = game.recordID.recordName
    }
    
    // MARK: - Convenience properties
    
    // Convert the record names of other players to CKReference objects
    var players: [CKRecord.Reference] {
        var result: [CKRecord.Reference] = []
        if let playersIDs = playersIDs {
            result = playersIDs.compactMap { CKRecord.Reference(recordID: CKRecord.ID(recordName: $0), action: .none) }
        }
        return result
    }
    
    // Convert the raw values of players status to enums
    var playersStatus: [Game.PlayerStatus] {
        var result: [Game.PlayerStatus] = []
        if let playersStatusRawValues = playersStatusRawValues {
            result = playersStatusRawValues.compactMap { Game.PlayerStatus(rawValue: $0) }
        }
        return result
    }
    
    // The name of the game winner
    private var gameWinner: String? {
        // Check if the highest score has reached the points needed to win, and if so, return the reference to that player
        guard let highestScore = playersPoints?.max(), highestScore == pointsToWin,
            let index = playersPoints?.firstIndex(of: highestScore)
            else { return nil }
        return playersNames?[index]
    }
    
    // A nicely formatted string describing the result of the game
    var gameStatusDescription: String {
        let winnerName = gameWinner
        if winnerName == UserController.shared.currentUser?.screenName {
            return "The game is over and you won!"
        } else {
            return "The game is over and \(winnerName ?? "nobody") has won"
        }
    }
    
    // The number of active players
    var numActivePlayers: Int {
        return playersStatus.filter({ $0 != .denied && $0 != .quit }).count
    }
    
    // All the active players sorted in descending order by number of points
    var sortedPlayers: [Player] {
        var result: [Player] = []
        // TODO: -
        return result
    }
}
