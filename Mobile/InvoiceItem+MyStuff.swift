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

@objc public enum InvoiceItemStatus : Int16 {
    case pending        = 0
    case received       = 1
    case damaged        = 2
    case outOfStock     = 3
    case promo          = 4
    case substitute     = 5
    case wrongItem      = 6

    var description: String {
        switch self {
        case .pending:
            return "Pending"
        case .received:
            return "Received"
        case .damaged:
            return "Damaged"
        case .outOfStock:
            return "Out of Stock"
        case .promo:
            return "Promotion"
        case .substitute:
            return "Substitute"
        case .wrongItem:
            return "Wrong Item"
        }
    }

    var shortDescription: String {
        switch self {
        case .pending:
            return "P"
        case .received:
            return "R"
        case .damaged:
            return "D"
        case .outOfStock:
            return "O"
        case .promo:
            return "Pr"
        case .substitute:
            return "Sub"
        case .wrongItem:
            return "WI"
        }
    }

    mutating func next() {
        switch self {
        case .pending:
            self = .received
        case .received:
            self = .damaged
        case .damaged:
            self = .outOfStock
        case .outOfStock:
            self = .promo
        case .promo:
            self = .substitute
        case .substitute:
            self = .wrongItem
        case .wrongItem:
            self = .pending
        }
    }

}

extension InvoiceItem {

    //@NSManaged var status: InvoiceItemStatus

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON, invoice: Invoice, uploaded: Bool = false) {
        self.init(context: context)

        // Properties
        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
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
        self.invoice = invoice
        if let itemID = json["item"]["id"].int32 {
            self.item = context.fetchWithRemoteID(Item.self, withID: itemID)
        }
        if let unitID = json["unit"]["id"].int32 {
            self.unit = context.fetchWithRemoteID(Unit.self, withID: unitID)
        }
    }

    // MARK: - Serialization

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        // TODO - remove the init of the different types?
        myDict["id"] = Int(self.remoteID)
        myDict["item_id"] = self.item?.remoteID
        myDict["quantity"] = Double(self.quantity)
        myDict["discount"] = Double(self.discount)
        myDict["cost"] = Double(self.cost)
        myDict["unit_id"] = self.unit?.remoteID
        //myDict["status"] = self.status
        return myDict
    }

}
