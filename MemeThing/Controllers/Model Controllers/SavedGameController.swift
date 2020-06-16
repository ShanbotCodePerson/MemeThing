//
//  SavedGameController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/15/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CoreData

class SavedGameController {
    
    // MARK: - Source of Truth
    
    static private var savedGames: [SavedGame] { loadFromCoreData() }
    static var finishedGames: [Game] { savedGames.compactMap({ Game(savedGame: $0) }).filter({ $0.gameStatus == .gameOver }) }
    
    // MARK: - CRUD Methods
    
    // Save a game to the Core Data
    static func save(_ game: Game) {
        print("got here to \(#function)")
        _ = SavedGame(game: game)
        saveToCoreData()
    }
    
//    // Load a game from the Core Data
//    static func loadGame(with recordName: String) -> SavedGame? {
//        let moc = CoreDataStack.context
//        let fetchRequest: NSFetchRequest<SavedGame> = SavedGame.fetchRequest()
//        fetchRequest.predicate = NSPredicate(format: "recordName == %@", argumentArray: [recordName])
//        let fetchResults = try? moc.fetch(fetchRequest)
//
//        return fetchResults?.first
//    }
    
    // Mark a game's status as over
    static func setToFinished(game recordName: String) {
        // Get the relevant game
        guard let savedGame = savedGames.first(where: { $0.recordName == recordName }) else { return }
        
        // Update the values in the Core Data
        savedGame.gameStatusRawValue = Int16(Game.GameStatus.gameOver.rawValue)
        
        // Save the changes
        saveToCoreData()
    }
    
    // Update a game in the Core Data
    static func update(_ game: Game) {
        // Get the relevant game
        guard let savedGame = savedGames.first(where: { $0.recordName == game.recordID.recordName }) else { return }
//        // Load the relevant game from the Core Data
//        guard let savedGame = loadGame(with: game.recordID.recordName) else { return }
        
        // Update the values in the Core Data
        savedGame.setValues(from: game)
        
        // Save the changes
        saveToCoreData()
    }
    
    // Delete a game from the Core Data
    static func delete(_ game: Game) {
        // Load the relevant game from the Core Data
        guard let savedGame = savedGames.first(where: { $0.recordName == game.recordID.recordName }),
            let moc = savedGame.managedObjectContext
            else { return }
        
        // Delete the game
        moc.delete(savedGame)
        
        // Save the changes
        saveToCoreData()
    }
    
    // MARK: - Persistence
    
    static private func loadFromCoreData() -> [SavedGame] {
        let moc = CoreDataStack.context
        let fetchRequest: NSFetchRequest<SavedGame> = SavedGame.fetchRequest()
        let fetchResults = try? moc.fetch(fetchRequest)
//        print("got here to \(#function) and there are \(fetchResults?.count) saved games")
        return fetchResults ?? []
    }
    
    static private func saveToCoreData() {
        let moc = CoreDataStack.context
        do {
            try moc.save()
        } catch let error {
            print("Error in saving to Core Data: \(error)")
        }
    }
}
