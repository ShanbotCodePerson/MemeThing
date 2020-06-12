//
//  FinishedGameController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/11/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CoreData

class FinishedGameController{
    
    // MARK: - Singleton
    
    static let shared = FinishedGameController()
    
    // MARK: - Source of Truth
    
    var finishedGames: [FinishedGame] { loadFromCoreData() }
    
    // MARK: - CRUD Methods
    
    // Create a finished game from a game object
    func newFinishedGame(from game: Game) {
        _ = FinishedGame(game: game)
        saveToCoreData()
    }
    
    // Delete a finished game from the core data
    func delete(_ finishedGame: FinishedGame) {
        if let moc = finishedGame.managedObjectContext {
            // Delete the game
            moc.delete(finishedGame)
            
            // Save the changes
            saveToCoreData()
        }
    }
    
    // MARK: - Persistence
    
    func loadFromCoreData() -> [FinishedGame] {
        // Get the playlists from the Core Data
        let moc = CoreDataStack.context
        let fetchRequest: NSFetchRequest<FinishedGame> = FinishedGame.fetchRequest()
        let fetchResults = try? moc.fetch(fetchRequest)
        
        return fetchResults ?? []
    }
    
    func saveToCoreData() {
        let moc = CoreDataStack.context
        do {
            try moc.save()
        } catch let saveError {
            print("Error in saving to Core Data: \(saveError)")
        }
    }
}
