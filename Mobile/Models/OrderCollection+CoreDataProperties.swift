//
//  OrderCollection+CoreDataProperties.swift
//  Mobile
//
//  Created by Mathew Gacy on 9/27/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//
//

import Foundation
import CoreData


extension OrderCollection {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderCollection> {
        return NSFetchRequest<OrderCollection>(entityName: "OrderCollection")
    }

    @NSManaged public var date: Date
    @NSManaged public var inventoryID: Int32
    @NSManaged public var storeID: Int32
    @NSManaged public var uploaded: Bool
    @NSManaged public var orders: NSSet?

}

// MARK: Generated accessors for orders
extension OrderCollection {

    @objc(addOrdersObject:)
    @NSManaged public func addToOrders(_ value: Order)

    @objc(removeOrdersObject:)
    @NSManaged public func removeFromOrders(_ value: Order)

    @objc(addOrders:)
    @NSManaged public func addToOrders(_ values: NSSet)

    @objc(removeOrders:)
    @NSManaged public func removeFromOrders(_ values: NSSet)

}
