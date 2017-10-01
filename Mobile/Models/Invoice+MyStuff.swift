//
//  Invoice+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/14/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

@objc public enum InvoiceStatus: Int16 {
    case pending        = 0
    case received       = 1
    case rejected       = 2
    //case paymentIssue     = 3

    static func asString(raw: Int16) -> String? {
        switch raw {
        case 0: return "pending"
        case 1: return "received"
        case 2: return "rejected"
        default: return nil
        }
    }

    init?(string: String) {
        switch string {
        case "pending": self = .pending
        case "complete": self = .received
        //case "pending": self = .rejected
        default: return nil
        }
    }

}

extension Invoice {

    //@NSManaged var ageType: InvoiceStatus

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON, parent: InvoiceCollection) {
        self.init(context: context)
        self.collection = parent
        update(context: context, withJSON: json)
    }

    // MARK: - Serialization

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
        //myDict["status"] = InvoiceStatus.asString(raw: status) ?? ""
        myDict["store_id"] = Int((self.collection?.storeID)!)

        if uploaded {
            myDict["status"] = "received"
        } else {
            myDict["status"] = "pending"
        }

        if let vendor = self.vendor {
            myDict["vendor_id"] = Int(vendor.remoteID)
        }

        // Generate array of dictionaries for InventoryItems
        guard let items = self.items else {
            log.error("\(#function) FAILED : unable to serialize without any InvoiceItems")
            return myDict
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

// MARK: - ManagedSyncable

extension Invoice: ManagedSyncable {

    public func update(context: NSManagedObjectContext, withJSON json: JSON) {
        log.debug("Updating with \(json)")

        // Required
        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
        if let shipDateString = json["ship_date"].string,
           let shipDate = shipDateString.toBasicDate() {
            self.shipDate = shipDate.timeIntervalSinceReferenceDate
        }
        if let receiveDateString = json["receive_date"].string,
           let receiveDate = receiveDateString.toBasicDate() {
            self.receiveDate = receiveDate.timeIntervalSinceReferenceDate
        }
        if let vendorID = json["vendor"]["id"].int32 {
            self.vendor = context.fetchWithRemoteID(Vendor.self, withID: vendorID)
        }
        if let statusString = json["status"].string {
            switch statusString {
            case "pending":
                self.uploaded = false
            case "completed":
                self.uploaded = true
            default:
                log.error("\(#function) - Invalid status: \(statusString)")
                self.uploaded = true
            }
        }

        // Optional
        if let invoiceNo = json["invoice_no"].int32 {
            self.invoiceNo = invoiceNo
        }
        if let credit = json["credit"].double {
            self.credit = credit
        }
        if let shipping = json["shipping"].double {
            self.shipping = shipping
        }
        if let taxes = json["taxes"].double {
            self.taxes = taxes
        }
        /// TODO: this should be a computed property
        if let totalCost = json["total_cost"].double {
            self.totalCost = totalCost
        }
        if let checkNo = json["check_no"].int32 {
            self.checkNo = checkNo
        }

        // Relationships
        if let items = json["items"].array {
            syncChildren(in: context, with: items)
        }
    }

}

// MARK: - SyncableParent

extension Invoice: SyncableParent {
    typealias ChildType = InvoiceItem

    func fetchChildDict(in context: NSManagedObjectContext) -> [Int32: ChildType]? {
        let fetchPredicate = NSPredicate(format: "invoice == %@", self)
        guard let objectDict = try? context.fetchEntityDict(ChildType.self, matching: fetchPredicate) else {
            return nil
        }
        return objectDict
    }

    func updateParent(of entity: ChildType) {
        entity.invoice = self
        //addToItems(entity)
    }

}
