//
//  Invoice+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/14/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData

@objc public enum InvoiceStatus: Int16 {
    case pending        = 0
    //case received       = 1
    case rejected       = 2
    //case paymentIssue   = 3
    case completed      = 4

    static func asString(raw: Int16) -> String? {
        switch raw {
        case 0: return "pending"
        //case 1: return "received"
        case 2: return "rejected"
        //case 3: return "payment_issue"
        case 4: return "completed"
        default: return nil
        }
    }

    init?(string: String) {
        switch string {
        case "pending": self = .pending
        //case "completed": self = .received
        case "rejected": self = .rejected
        //case "payment_issue": self = .paymentIssue
        case "completed": self = .completed
        default: return nil
        }
    }

}

// MARK: - NewSyncable

extension Invoice: NewSyncable {
    typealias RemoteType = RemoteInvoice
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: RemoteIdentifierType { return self.remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        remoteID = record.syncIdentifier
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        // Required
        //remoteID = record.syncIdentifier
        guard let shipDate = record.shipDate.toBasicDate(), let receiveDate = record.receiveDate.toBasicDate() else {
            fatalError("\(#function) FAILED : unable to parse shipDate or receiveDate from \(record)")
        }
        self.shipDate = shipDate.timeIntervalSinceReferenceDate
        self.receiveDate = receiveDate.timeIntervalSinceReferenceDate

        if record.vendor.syncIdentifier != vendor?.remoteIdentifier {
            vendor = Vendor.updateOrCreate(with: record.vendor, in: context)
        }
        /// TODO: switch to method on `InvoiceStatus`
        switch record.status {
        case .pending:
            self.uploaded = false
            status = InvoiceStatus.pending.rawValue
        case .completed:
            self.uploaded = true
            status = InvoiceStatus.completed.rawValue
        case .rejected:
            status = InvoiceStatus.rejected.rawValue
        }

        // Optional
        if let invoiceNo = record.invoiceNo {
            self.invoiceNo = Int32(invoiceNo)
        }
        if let credit = record.credit {
            self.credit = credit
        }
        if let shipping = record.shipping {
            self.shipping = shipping
        }
        if let taxes = record.taxes {
            self.taxes = taxes
        }
        /// TODO: this should be a computed property
        if let totalCost = record.totalCost {
            self.totalCost = totalCost
        }
        if let checkNo = record.checkNo {
            self.checkNo = Int32(checkNo)
        }

        // Relationships
        syncChildren(with: record.items, in: context)
    }

}

// MARK: - NewSyncableParent

extension Invoice: NewSyncableParent {
    typealias ChildType = InvoiceItem

    func fetchChildDict(in context: NSManagedObjectContext) -> [Int32: InvoiceItem]? {
        let fetchPredicate = NSPredicate(format: "invoice == %@", self)
        guard let objectDict = try? ChildType.fetchEntityDict(in: context, matching: fetchPredicate) else {
            return nil
        }
        return objectDict
    }

    func updateParent(of entity: InvoiceItem) {
        entity.invoice = self
    }

}

// MARK: - Serialization

extension Invoice {

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        myDict["id"] = Int(self.remoteID)
        myDict["invoice_no"] = Int(self.invoiceNo)
        myDict["ship_date"] = shipDate.toPythonDateString()
        myDict["receive_date"] = receiveDate.toPythonDateString()
        myDict["credit"] = Double(self.credit)
        myDict["shipping"] = Double(self.shipping)
        myDict["taxes"] = Double(self.taxes)
        /// FIXME: why is total_cost not Double?
        myDict["total_cost"] = Int(self.totalCost)
        myDict["check_no"] = Int(self.checkNo)
        myDict["status"] = InvoiceStatus.asString(raw: status) ?? ""
        myDict["store_id"] = Int((self.collection?.storeID)!)
        guard let vendor = self.vendor else {
            log.error("\(#function) FAILED : unable to serialize without a Vendor")
            return nil
        }
        myDict["vendor_id"] = Int(vendor.remoteID)

        // Generate array of dictionaries for InventoryItems
        guard let items = self.items else {
            log.error("\(#function) FAILED : unable to serialize without any InvoiceItems")
            return nil
        }

        /// TODO: use map / flatmap / reduce
        var itemsArray = [[String: Any]]()
        for case let item as InvoiceItem in items {
            if let itemDict = item.serialize() {
                itemsArray.append(itemDict)
            }
        }
        myDict["items"] = itemsArray

        return myDict
    }

}
