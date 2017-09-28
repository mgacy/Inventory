//
//  InvoiceCollection+CoreDataProperties.swift
//  Mobile
//
//  Created by Mathew Gacy on 9/26/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//
//

import Foundation
import CoreData

extension InvoiceCollection {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<InvoiceCollection> {
        return NSFetchRequest<InvoiceCollection>(entityName: "InvoiceCollection")
    }

    @NSManaged public var date: Date
    @NSManaged public var storeID: Int32
    @NSManaged public var uploaded: Bool
    @NSManaged public var invoices: NSSet?

}

// MARK: Generated accessors for invoices
extension InvoiceCollection {

    @objc(addInvoicesObject:)
    @NSManaged public func addToInvoices(_ value: Invoice)

    @objc(removeInvoicesObject:)
    @NSManaged public func removeFromInvoices(_ value: Invoice)

    @objc(addInvoices:)
    @NSManaged public func addToInvoices(_ values: NSSet)

    @objc(removeInvoices:)
    @NSManaged public func removeFromInvoices(_ values: NSSet)

}
