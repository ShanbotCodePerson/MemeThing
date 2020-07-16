//
//  Game.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/30/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

// MARK: - String Constants

struct GameStrings {
    static let recordType = "Game"
    static let playersIDsKey = "playersIDs"
    static let playersNamesKey = "playersNames"
    static let playersStatusKey = "playersStatus"
    static let playersPointsKey = "playersPoints"
    fileprivate static let leadPlayerIDKey = "leadPlayerID"
    fileprivate static let memesKey = "memes"
    static let pointsToWinKey = "pointsLimit"
    fileprivate static let gameStatusKey = "gameStatus"
    static let recordIDKey = "recordID"
}

class Game {
    
    // MARK: - Properties
    
    var playersIDs: [String]
    var playersNames: [String]
    var playersStatus: [PlayerStatus]
    var playersPoints: [Int]
    private var playersInfo: [String : Player] {
        var result = [String : Player]()
        for index in 0..<playersIDs.count {
            let player = Player(name: playersNames[index], status: self.playersStatus[index], points: self.playersPoints[index])
            result[playersIDs[index]] = player
        }
        return result
    }
    var leadPlayerID: String
    var memes: [String]?
    var pointsToWin: Int
    var gameStatus: GameStatus
    let recordID: String
    var documentID: String?
    
    // Player Struct
    struct Player {
        var name: String
        var status: PlayerStatus
        var points: Int
    }
    
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
    
    // All the active players, filtering out those who denied the invitation or quit the game
    var activePlayers: [String : Player] {
        return playersInfo.filter { $1.status != .denied && $1.status != .quit }
    }
    
    // All the references for the active players
    var activePlayersIDs: [String] {
        return playersIDs.filter({ activePlayers.keys.contains($0) })
    }
    
    // All the active players, sorted in descending order by points
    var sortedPlayers: [Player] {
        return activePlayers.values.sorted { (player1, player2) -> Bool in
            // If the points are equal, sort by name
            if player1.points == player2.points {
                // If the names are equal, sort by status
                if player1.name == player2.name {
                    return player1.status.rawValue > player2.status.rawValue
                }
                return player1.name > player2.name
            }
            return player1.points > player2.points
        }
    }
    
    // A nicely formatted list of the names of the active game participants, minus the current user
    var listOfPlayerNames: String {
        guard let currentUser = UserController.shared.currentUser else { return "ERROR" }
        let otherPlayers = activePlayers.filter { $0.key != currentUser.recordID }
        return otherPlayers.compactMap({ $1.name }).joined(separator: ", ")
    }
    
    // The name of the lead player
    var leadPlayerName: String {
        guard let index = playersIDs.firstIndex(of: leadPlayerID) else { return "" }
        return playersNames[index]
    }
    
    // A nicely formatted string to tell a given user what phase the game is currently in
    var gameStatusDescription: String {
        guard let currentUser = UserController.shared.currentUser else { return "ERROR" }
        let isLeadPlayer = (leadPlayerID == currentUser.recordID)
        
        // Describe the current phase of the game based on the game status and whether the user is currently the lead player or not
        switch gameStatus {
        case .waitingForPlayers:
            let numberWaiting = playersStatus.filter({ $0 == .invited}).count
            return "The game has not started yet - still waiting for \(numberWaiting) player\(numberWaiting == 1 ? "" : "s") to join the game"
        case .waitingForDrawing:
            if isLeadPlayer {
                return "The other players are waiting on you to complete a drawing"
            } else {
                return "Waiting for \(leadPlayerName) to complete a drawing"
            }
        case .waitingForCaptions:
            let numberWaiting = playersStatus.filter({ $0 == .accepted}).count
            if isLeadPlayer {
                return "Waiting for \(numberWaiting) player\(numberWaiting == 1 ? "" : "s") to write a caption for your drawing"
            } else if getStatus(of: currentUser) == .sentCaption {
                return "Waiting for \(numberWaiting) player\(numberWaiting == 1 ? "" : "s") to write a caption for \(leadPlayerName)'s drawing"
            } else {
                return "The other players are waiting for you to write a caption for \(leadPlayerName)'s drawing"
            }
        case .waitingForResult:
            if isLeadPlayer  {
                return "The other players are waiting for you to select the funniest caption"
            } else {
                return "Waiting for \(leadPlayerName) to select the funniest caption"
            }
        case .waitingForNextRound:
            if isLeadPlayer {
                return "Starting a new round with you as the lead player"
            } else {
                return "Starting a new round with \(leadPlayerName) as the lead player"
            }
        case .gameOver:
            let winnerName = gameWinner
            if winnerName == currentUser.screenName {
                return "The game is over and you won!"
            } else {
                return "The game is over and \(winnerName ?? "nobody") has won"
            }
        }
    }
    
    // Calculate whether there are enough players available to continue the game
    var enoughPlayers: Bool {
        // A minimum of three players is required to play the game
        return activePlayers.count > 2
    }
    
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
    
    // Calculate whether all players have seen the finished game and it's ready to be deleted
    var allPlayersDone: Bool {
        let activeStatus = activePlayers.map { $1.status }
        return Set(activeStatus) == [.done]
    }
    
    // Figure out if a player has won the game yet
    var gameWinner: String? {
        // Check if the highest score has reached the points needed to win, and if so, return the reference to that player
        guard let highestScore = playersPoints.max(), highestScore == pointsToWin,
            let index = playersPoints.firstIndex(of: highestScore)
            else { return nil }
        return playersNames[index]
    }
    
    // MARK: - Initializers
    
    init(playersIDs: [String],
         playersNames: [String],
         playersStatus: [PlayerStatus]? = nil,
         playersPoints: [Int]? = nil,
         leadPlayerID: String,
         memes: [String]? = nil,
         pointsToWin: Int = 3,
         gameStatus: GameStatus = .waitingForPlayers,
         recordID: String = UUID().uuidString) {
        
        self.playersIDs = playersIDs
        self.playersNames = playersNames
        if let playersStatus = playersStatus { self.playersStatus = playersStatus }
        else {
            // By default, the initial status of all players is waiting, except for the lead player (who starts off at the first index)
            self.playersStatus = Array(repeating: .invited, count: playersIDs.count - 1)
            self.playersStatus.insert(.accepted, at: 0)
        }
        if let playersPoints = playersPoints { self.playersPoints = playersPoints }
        else {
            // By default, all players start with zero points
            self.playersPoints = Array(repeating: 0, count: playersIDs.count)
        }
        self.leadPlayerID = leadPlayerID
        self.memes = memes
        self.pointsToWin = pointsToWin
        self.gameStatus = gameStatus
        self.recordID = recordID
    }
    
    convenience init?(dictionary: [String : Any]) {
        guard let playersIDs = dictionary[GameStrings.playersIDsKey] as? [String],
            let playersNames = dictionary[GameStrings.playersNamesKey] as? [String],
            let playersStatusRawValues = dictionary[GameStrings.playersStatusKey] as? [Int],
            let playersPoints = dictionary[GameStrings.playersPointsKey] as? [Int],
            let leadPlayerID = dictionary[GameStrings.leadPlayerIDKey] as? String,
            let pointsToWin = dictionary[GameStrings.pointsToWinKey] as? Int,
            let gameStatusRawValue = dictionary[GameStrings.gameStatusKey] as? Int,
            let gameStatus = GameStatus(rawValue: gameStatusRawValue),
            let recordID = dictionary[GameStrings.recordIDKey] as? String
            else { return nil }
        let memes = dictionary[GameStrings.memesKey] as? [String]
        let playersStatus = playersStatusRawValues.compactMap({ PlayerStatus(rawValue: $0) })
        
        self.init(playersIDs: playersIDs,
                  playersNames: playersNames,
                  playersStatus: playersStatus,
                  playersPoints: playersPoints,
                  leadPlayerID: leadPlayerID,
                  memes: memes,
                  pointsToWin: pointsToWin,
                  gameStatus: gameStatus,
                  recordID: recordID)
    }
    
    // MARK: - Convert to Dictionary
    
    func asDictionary() -> [String : Any] {
        [GameStrings.playersIDsKey : playersIDs,
         GameStrings.playersNamesKey : playersNames,
         GameStrings.playersStatusKey : playersStatus.compactMap({ $0.rawValue }),
         GameStrings.playersPointsKey : playersPoints,
         GameStrings.leadPlayerIDKey : leadPlayerID,
         GameStrings.memesKey : memes as Any,
         GameStrings.pointsToWinKey : pointsToWin,
         GameStrings.gameStatusKey : gameStatus.rawValue,
         GameStrings.recordIDKey : recordID]
    }
    
    // MARK: - Helper Methods
    
    // Quickly get a user's status
    func getStatus(of player: User) -> PlayerStatus {
        playersInfo[player.recordID]?.status ?? .quit
    }
    
    // Quickly update a player's status
    func updateStatus(of player: User, to status: PlayerStatus) {
        guard let index = playersIDs.firstIndex(of: player.recordID) else { return }
        playersStatus[index] = status
    }
    
    // Quickly get a user's points
    func getPoints(of player: User) -> Int {
        playersInfo[player.recordID]?.points ?? 0
    }
    
    // Quickly update a player's points
    func updatePoints(of player: User, to points: Int) {
        guard let index = playersIDs.firstIndex(of: player.recordID) else { return }
        playersPoints[index] = points
    }
    
    // Quickly update a the game when a caption is selected as winner
    func winningCaptionSelected(as caption: Caption) {
        // Update the points of the player who submitted that caption
        guard let index = playersIDs.firstIndex(of: caption.authorID) else { return }
        playersPoints[index] += 1
        
        // Check to see if this results in an overall winner of the game, and update the status of the game accordingly
        if gameWinner != nil { gameStatus = .gameOver }
        else { gameStatus = .waitingForDrawing }
    }
    
    // Quickly get the name of a player from their recordID
    func getName(of recordID: String) -> String {
        guard let index = playersIDs.firstIndex(of: recordID) else { return "ERROR" }
        return playersNames[index]
    }
    
    // Reset the game for a new round
    func resetGame() {
        // Update the game's status
        gameStatus = .waitingForDrawing
        
        // Increment the lead player, looping back to the beginning if necessary
        guard var index = activePlayersIDs.firstIndex(of: leadPlayerID) else { return }
        index = (index + 1) % activePlayersIDs.count
        leadPlayerID = activePlayersIDs[index]
        
        // Reset the status of all the active players
        for index in 0..<playersStatus.count {
            if playersStatus[index] == .sentCaption || playersStatus[index] == .sentDrawing {
                playersStatus[index] = .accepted
            }
        }
    }
    
    // Reset the game's status based on the players status
    func resetGameStatus() {
        if !enoughPlayers || gameWinner != nil { gameStatus = .gameOver }
        else if allCaptionsSubmitted { gameStatus = .waitingForResult }
        else if allPlayersResponded { gameStatus = .waitingForDrawing }
    }
}

// MARK: - Equatable

extension Game: Equatable {
    static func == (lhs: Game, rhs: Game) -> Bool {
        return lhs.recordID == rhs.recordID
    }
}
