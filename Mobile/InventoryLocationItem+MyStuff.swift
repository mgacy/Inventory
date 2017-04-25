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

    // For InventoryLocationItems belonging to an InventoryLocation
    convenience init(context: NSManagedObjectContext, itemID: Int,
                     position: Int?, location: InventoryLocation) {
        self.init(context: context)

        self.itemID = Int32(itemID)
        if let _position = position {
            self.position = Int16(_position)
        }

        // Relationships
        self.location = location

        // Try to find corresponding InventoryItem and add relationship
        guard let parent = location.inventory else { return }

        if let item = fetchInventoryItem(context: context, inventory: parent, itemID: itemID) {
            self.item = item
        } else {
            /// TODO: init should fail since self.item is required
            print("Unable to fetch InventoryItem \(itemID) for InventoryLocation \(location)")
        }
    }

    // For InventoryLocationItems belonging to an InventoryLocationCategory
    convenience init(context: NSManagedObjectContext, itemID: Int,
                     category: InventoryLocationCategory) {
        self.init(context: context)
        self.itemID = Int32(itemID)

        // Relationships
        self.category = category

        // Try to find corresponding InventoryItem and add relationship
        guard let location = category.location else { return }
        guard let parent = location.inventory else { return }

        if let item = fetchInventoryItem(context: context, inventory: parent, itemID: itemID) {
            self.item = item
        } else {
            /// TODO: init should fail since self.item is required
            print("Unable to fetch InventoryItem \(itemID) for InventoryLocationCategory \(category)")
        }
    }

    // MARK: - Establish Relationships

    func fetchInventoryItem(context: NSManagedObjectContext, inventory: Inventory, itemID: Int) -> InventoryItem? {
        let predicate1 = NSPredicate(format: "itemID == \(Int32(itemID))")
        let predicate2 = NSPredicate(format: "inventory == %@", inventory)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
        return context.fetchSingleEntity(InventoryItem.self, matchingPredicate: predicate)
    }

}
