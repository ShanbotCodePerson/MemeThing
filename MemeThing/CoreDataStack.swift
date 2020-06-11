//
//  CoreDataStack.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/11/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    private static let container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MemeThing")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    static var context: NSManagedObjectContext { return container.viewContext }
    
}
