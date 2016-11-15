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

extension Invoice {

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON, collection: InvoiceCollection, uploaded: Bool = false) {
        self.init(context: context)

        // Properties
        if let remoteID = json["remote_id"].int {
            self.remoteID = Int32(remoteID)
        }
        if let invoiceNo = json["invoice_no"].int {
            self.invoiceNo = Int32(invoiceNo)
        }
        //if let storeID = json["store_id"].int {
        //    self.storeID = storeID
        //}
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
        // TODO - this should be a computed property
        if let totalCost = json["total_cost"].double {
            self.totalCost = totalCost
        }
        if let checkNo = json["check_no"].int {
            self.checkNo = Int32(checkNo)
        }
        self.uploaded = uploaded
        
        // TODO - status
        //if let status = json["status"] {
        //    self.status = status
        //}

        // self.vendorID = vendor_id
        // self.vendorName = vendor_name

        // Relationships
        if let items = json["items"].array {
            for itemJSON in items {
                _ = InvoiceItem(context: context, json: itemJSON, invoice: self)
            }
        }
    }

    // MARK: - Serialization

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        myDict["id"] = Int(self.remoteID)
        myDict["invoiceNo"] = Int(self.invoiceNo)
        myDict["ship_date"] = self.shipDate
        myDict["receive_date"] = self.receiveDate
        myDict["credit"] = Double(self.credit)
        myDict["shipping"] = Double(self.shipping)
        myDict["taxes"] = Double(self.taxes)
        myDict["total_cost"] = Int(self.totalCost)
        myDict["check_no"] = Int(self.checkNo)

        // Generate array of dictionaries for InventoryItems
        guard let items = self.items else {
            print("\nPROBLEM - Unable to serialize without any InvoiceItems")
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
