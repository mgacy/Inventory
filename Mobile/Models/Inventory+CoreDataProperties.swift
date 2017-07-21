//
//  Inventory+CoreDataProperties.swift
//  Mobile
//
//  Created by Mathew Gacy on 7/20/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData

extension Inventory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Inventory> {
        return NSFetchRequest<Inventory>(entityName: "Inventory")
    }

    @NSManaged public var date: Date
    @NSManaged public var remoteID: Int32
    @NSManaged public var storeID: Int32
    @NSManaged public var typeID: Int32
    @NSManaged public var uploaded: Bool
    @NSManaged public var items: NSSet?
    @NSManaged public var locations: NSSet?
    @NSManaged public var store: Store?

}

// MARK: Generated accessors for items
extension Inventory {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: InventoryItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: InventoryItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

// MARK: Generated accessors for locations
extension Inventory {

    @objc(addLocationsObject:)
    @NSManaged public func addToLocations(_ value: InventoryLocation)

    @objc(removeLocationsObject:)
    @NSManaged public func removeFromLocations(_ value: InventoryLocation)

    @objc(addLocations:)
    @NSManaged public func addToLocations(_ values: NSSet)

    @objc(removeLocations:)
    @NSManaged public func removeFromLocations(_ values: NSSet)

}
