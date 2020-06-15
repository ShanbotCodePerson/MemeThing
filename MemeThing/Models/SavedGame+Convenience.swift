//
//  SavedGame+Convenience.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/15/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

extension SavedGame {
    
    convenience init(game: Game, context: NSManagedObjectContext = CoreDataStack.context) {
        self.init(context: context)
        
        setValues(from: game)
    }
    
    func setValues(from game: Game) {
        self.playersReferencesData = game.playersReferences.map({ $0.recordID.recordName }).description.data(using: String.Encoding.utf16)
        self.playersNamesData = game.playersNames.description.data(using: String.Encoding.utf16)
        self.playersStatusData = game.playersStatus.map({ $0.rawValue }).description.data(using: String.Encoding.utf16)
        self.playersPointsData = game.playersPoints.description.data(using: String.Encoding.utf16)
        self.leadPlayerRecordName = game.leadPlayer.recordID.recordName
        self.memesData = game.memes?.description.data(using: String.Encoding.utf16)
        self.gameStatusRawValue = Int16(game.gameStatus.rawValue)
        self.recordName = game.recordID.recordName
    }
}
