//
//  Order+CoreDataProperties.swift
//  Mobile
//
//  Created by Mathew Gacy on 7/20/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData


extension Order {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Order> {
        return NSFetchRequest<Order>(entityName: "Order")
    }

    @NSManaged public var date: Date
    @NSManaged public var placed: Bool
    @NSManaged public var remoteID: Int32
    @NSManaged public var status: Int16
    @NSManaged public var uploaded: Bool
    @NSManaged public var vendorID: Int32
    @NSManaged public var collection: OrderCollection?
    @NSManaged public var items: NSSet?
    @NSManaged public var store: Store?
    @NSManaged public var vendor: Vendor?

}

// MARK: Generated accessors for items
extension Order {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: OrderItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: OrderItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}
