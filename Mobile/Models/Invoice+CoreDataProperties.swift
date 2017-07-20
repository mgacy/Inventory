//
//  Invoice+CoreDataProperties.swift
//  Mobile
//
//  Created by Mathew Gacy on 7/20/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData


extension Invoice {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Invoice> {
        return NSFetchRequest<Invoice>(entityName: "Invoice")
    }

    @NSManaged public var checkNo: Int32
    @NSManaged public var credit: Double
    @NSManaged public var date: Date
    @NSManaged public var invoiceNo: Int32
    @NSManaged public var receiveDate: Date?
    @NSManaged public var remoteID: Int32
    @NSManaged public var shipDate: Date?
    @NSManaged public var shipping: Double
    @NSManaged public var taxes: Double
    @NSManaged public var totalCost: Double
    @NSManaged public var uploaded: Bool
    @NSManaged public var collection: InvoiceCollection?
    @NSManaged public var items: NSSet?
    @NSManaged public var vendor: Vendor?

}

// MARK: Generated accessors for items
extension Invoice {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: InvoiceItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: InvoiceItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}
