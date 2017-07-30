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

    @NSManaged var ageType: InvoiceStatus

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON, collection: InvoiceCollection, uploaded: Bool = false) {
        self.init(context: context)

        // Properties

        if let remoteID = json["remote_id"].int32 {
            self.remoteID = remoteID
        }
        if let invoiceNo = json["invoice_no"].int32 {
            self.invoiceNo = invoiceNo
        }
        if let shipDate = json["ship_date"].string {
            self.shipDate = shipDate
        }
        if let receiveDate = json["receive_date"].string {
            self.receiveDate = receiveDate
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
        self.uploaded = uploaded

        /// TODO: status
        //if let status = json["status"] {
        //    self.status = status
        //}

        // Relationships
        self.collection = collection
        /// TODO: error / log if these fail
        if let items = json["items"].array {
            for itemJSON in items {
                _ = InvoiceItem(context: context, json: itemJSON, invoice: self, uploaded: uploaded)
            }
        }
        if let vendorID = json["vendor"]["id"].int32 {
            self.vendor = context.fetchWithRemoteID(Vendor.self, withID: vendorID)
        }
    }

    // MARK: - Serialization

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        myDict["id"] = Int(self.remoteID)
        myDict["invoice_no"] = Int(self.invoiceNo)
        myDict["ship_date"] = self.shipDate
        myDict["receive_date"] = self.receiveDate
        myDict["credit"] = Double(self.credit)
        myDict["shipping"] = Double(self.shipping)
        myDict["taxes"] = Double(self.taxes)
        myDict["total_cost"] = Int(self.totalCost)
        myDict["check_no"] = Int(self.checkNo)
        myDict["store_id"] = Int((self.collection?.storeID)!)

        if let vendor = self.vendor {
            myDict["vendor_id"] = Int(vendor.remoteID)
        }

        // Generate array of dictionaries for InventoryItems
        guard let items = self.items else {
            log.error("\(#function) FAILED : unable to serialize without any InvoiceItems")
            return myDict
        }

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
