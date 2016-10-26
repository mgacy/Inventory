//
//  InventoryLocationItem+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension InventoryLocationItem {
    
    // MARK: - Lifecycle
    
    convenience init(context: NSManagedObjectContext, itemID: Int,
                     position: Int?, location: InventoryLocation) {
        self.init(context: context)
    
        self.itemID = Int32(itemID)
        if let _position = position {
            self.position = Int16(_position)
        }
        
        // Relationships
        self.location = location
        
        // Try to find corresponding item and add relationship
        if let item = fetchInventoryItem(context: context, itemID: itemID) {
            // print("Found Item: \(item)")
            self.item = item
        }
    
    }
    
    convenience init(context: NSManagedObjectContext, itemID: Int,
                     category: InventoryLocationCategory) {
        self.init(context: context)
        self.itemID = Int32(itemID)
        
        // Relationships
        self.category = category
        
        // Try to find corresponding item and add relationship
        if let item = fetchInventoryItem(context: context, itemID: itemID) {
            // print("Found Item: \(item)")
            self.item = item
        }
    }
    
    // MARK: - Establish Relationships
    
    // TODO: go ahead and just set relationship here?
    func fetchInventoryItem(context: NSManagedObjectContext,
                            itemID: Int) -> InventoryItem? {
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        
        request.predicate = NSPredicate(format: "itemID == \(Int32(itemID))")
        
        do {
            let searchResults = try context.fetch(request)
            
            switch searchResults.count {
            case 0:
                print("Unable to find Item with id: \(itemID)")
                return nil
            case 1:
                return searchResults[0]
            default:
                print("Found multiple matches for InventoryItem with id: \(itemID) - \(searchResults)")
                return searchResults[0]
            }
            
        } catch {
            print("Error with request: \(error)")
        }
        return nil
    }
    
    func fetchUnit(context: NSManagedObjectContext, id: Int) {
        let request: NSFetchRequest<Unit> = Unit.fetchRequest()
        
        request.predicate = NSPredicate(format: "remoteID == \(Int32(id))")
        
        do {
            let searchResults = try context.fetch(request)
            
            switch searchResults.count {
            case 0:
                print("PROBLEM - Unable to find Unit with id: \(id)")
                return
            case 1:
                self.unit = searchResults[0]
            default:
                print("Found multiple matches for unit with id: \(id) - \(searchResults)")
                self.unit = searchResults[0]
            }
            
        } catch {
            print("Error with request: \(error)")
        }
    }
    
}
