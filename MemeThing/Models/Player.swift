//
//  Player.swift
//  MemeThing
//
//  Created by Shannon Draeker on 8/1/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// MARK: - String Constants

struct PlayerStrings {
    static let recordType = "Player"
    fileprivate static let playerNameKey = "playerName"
    fileprivate static let playerStatusKey = "playerStatus"
    fileprivate static let playerPointsKey = "playerPoints"
    static let playerRecordIDKey = "playerRecordID"
}

// MARK: - Player Status

// Player Status
enum PlayerStatus: Int {
    case invited
    case accepted
    case denied
    case quit
    case sentDrawing
    case sentCaption
    case done
    
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
        case .done:
            return "Done"
        }
    }
}

class Player {
    
    // MARK: - Properties
    
    let playerName: String
    var playerStatus: PlayerStatus
    var playerPoints: Int
    let playerRecordID: String
    
    // MARK: - Initializer
    
    init(playerName: String,
         playerStatus: PlayerStatus = .invited,
         playerPoints: Int = 0,
         playerRecordID: String = UUID().uuidString) {
        
        self.playerName = playerName
        self.playerStatus = playerStatus
        self.playerPoints = playerPoints
        self.playerRecordID = playerRecordID
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let playerName = dictionary[PlayerStrings.playerNameKey] as? String,
            let playerStatusRawValue = dictionary[PlayerStrings.playerStatusKey] as? Int,
            let playerStatus = PlayerStatus(rawValue: playerStatusRawValue),
            let playerPoints = dictionary[PlayerStrings.playerPointsKey] as? Int,
            let playerRecordID = dictionary[PlayerStrings.playerRecordIDKey] as? String
            else { return nil }
        
        self.init(playerName: playerName, playerStatus: playerStatus, playerPoints: playerPoints, playerRecordID: playerRecordID)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [PlayerStrings.playerNameKey : playerName,
         PlayerStrings.playerStatusKey : playerStatus.rawValue,
         PlayerStrings.playerPointsKey : playerPoints,
         PlayerStrings.playerRecordIDKey : playerRecordID]
    }
}
