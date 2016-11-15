//
//  InvoiceItem+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/14/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension InvoiceItem {

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON, invoice: Invoice, uploaded: Bool = false) {
        self.init(context: context)

        // Properties
        if let remoteID = json["id"].int {
            self.remoteID = Int32(remoteID)
        }
        if let quantity = json["quantity"].double {
            self.quantity = quantity
        }
        if let discount = json["discount"].double {
            self.discount = discount
        }
        if let cost = json["cost"].double {
            self.cost = cost
        }

        // TODO - status

        // Relationships
        if let itemID = json["item"]["id"].int {
            self.item = context.fetchWithID(Item.self, withID: itemID)
        }
        if let unitID = json["unit_id"].int {
            self.unit = context.fetchWithID(Unit.self, withID: unitID)
        }

    }

    // MARK: - Serialization

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        // TODO - remove the init of the different types?
        myDict["id"] = Int(self.remoteID)
        myDict["quantity"] = Double(self.quantity)
        myDict["discount"] = Double(self.discount)
        myDict["cost"] = Double(self.cost)
        myDict["unit_id"] = self.unit?.remoteID
        return myDict
    }

}
