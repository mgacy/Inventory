//
//  InvoiceItem+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/14/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData

@objc public enum InvoiceItemStatus: Int16 {
    case pending        = 0
    case received       = 1
    case damaged        = 2
    case outOfStock     = 3
    case promo          = 4
    case substitute     = 5
    case wrongItem      = 6
    case notReceived    = 7

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
        case .notReceived:
            return "Not Received"
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
        case .notReceived:
            return "NR"
        }
    }

    static func asString(raw: Int16) -> String? {
        switch raw {
        case 0: return "pending"
        case 1: return "received"
        case 2: return "damaged"
        case 3: return "outOfStock"
        case 4: return "promo"
        case 5: return "substitute"
        case 6: return "wrongItem"
        case 7: return "notReceived"
        default: return nil
        }
    }

    init(recordStatus status: RemoteInvoiceItem.Status) {
        switch status {
        case .pending: self = .pending
        case .received: self = .received
        case .damaged: self = .damaged
        case .outOfStock: self = .outOfStock
        case .promo: self = .promo
        case .substitute: self = .substitute
        case .wrongItem: self = .wrongItem
        case .notReceived: self = .notReceived
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
            self = .notReceived
        case .notReceived:
            self = .pending
        }
    }

}

// MARK: - Syncable

extension InvoiceItem: Syncable {
    typealias RemoteType = RemoteInvoiceItem
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
        quantity = record.quantity
        self.status = InvoiceItemStatus(recordStatus: record.status).rawValue

        // Optional
        discount = record.discount ?? 0.0
        cost = record.cost ?? 0.0

        // Relationships
        if record.item.syncIdentifier != self.item?.remoteID {
            let predicate = NSPredicate(format: "remoteID == \(record.item.syncIdentifier)")
            if let existingObject = Item.findOrFetch(in: context, matching: predicate) {
                self.item = existingObject
            } else {
                log.error("\(#function) FAILED : unable to fetch Item \(record.item)")
            }
        }

        if record.unit.syncIdentifier != self.unit?.remoteID {
            guard let newUnit = Unit.fetchWithRemoteIdentifier(record.unit.syncIdentifier, in: context) else {
                log.error("\(#function) FAILED : unable to fetch Item \(record.unit)"); return
            }
            self.unit = newUnit
        }
    }

}

// MARK: - Serialization

extension InvoiceItem {

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        /// TODO: remove the init of the different types?
        myDict["id"] = Int(self.remoteID)
        myDict["item_id"] = self.item?.remoteID
        myDict["quantity"] = Double(self.quantity)
        myDict["discount"] = Double(self.discount)
        myDict["cost"] = Double(self.cost)
        myDict["unit_id"] = self.unit?.remoteID
        myDict["status"] = InvoiceItemStatus.asString(raw: status) ?? ""
        return myDict
    }

}
