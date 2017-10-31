//
//  InventoryLocationItem+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData

extension InventoryLocationItem {

    // MARK: - Lifecycle

    // For InventoryLocationItems belonging to an InventoryLocation
    convenience init(context: NSManagedObjectContext, itemID: Int,
                     location: InventoryLocation, position: Int) {
        self.init(context: context)
        self.itemID = Int32(itemID)
        self.position = Int16(position)

        // Relationships
        self.location = location

        // Try to find corresponding InventoryItem and add relationship
        guard let parent = location.inventory else { return }

        if let item = fetchInventoryItem(context: context, inventory: parent, itemID: itemID) {
            self.item = item
        } else {
            /// TODO: init should fail since self.item is required
            log.error("\(#function) FAILED : unable to fetch InventoryItem \(itemID) for InventoryLocation \(location)")
        }
    }

    // For InventoryLocationItems belonging to an InventoryLocationCategory
    convenience init(context: NSManagedObjectContext, itemID: Int,
                     category: InventoryLocationCategory, position: Int) {
        self.init(context: context)
        self.itemID = Int32(itemID)
        self.position = Int16(position)

        // Relationships
        self.category = category

        // Try to find corresponding InventoryItem and add relationship
        guard let location = category.location else { return }
        guard let parent = location.inventory else { return }

        if let item = fetchInventoryItem(context: context, inventory: parent, itemID: itemID) {
            self.item = item
        } else {
            /// TODO: init should fail since self.item is required
            // swiftlint:disable:next line_length
            log.error("\(#function) FAILED : unable to fetch InventoryItem \(itemID) for InventoryLocationCategory \(category)")
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

extension InventoryLocationItem: Managed {}
