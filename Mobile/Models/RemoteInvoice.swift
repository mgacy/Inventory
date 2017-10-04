//
//  RemoteInvoice.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/4/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation

// MARK: - InvoiceCollection

struct RemoteInvoiceCollection: Codable {

    // enum InvoiceCollectionStatus {}

    //let date: Date
    let date: String
    let status: String
    let storeID: Int
    let invoices: [RemoteInvoice]

    private enum CodingKeys: String, CodingKey {
        case date
        case status
        case storeID = "store_id"
        case invoices
    }
}

extension RemoteInvoiceCollection: RemoteRecord {
    typealias SyncIdentifierType = Date
    var syncIdentifier: SyncIdentifierType { return date.toBasicDate() ?? Date() }
}

// MARK: - Invoice

struct RemoteInvoice: Codable {

    // enum InvoiceStatus {}

    let remoteID: Int
    let shipDate: String
    let receiveDate: String
    let status: String
    let storeID: Int
    // Optional
    let invoiceNo: Int?
    let checkNo: Int?
    let credit: Double?
    let shipping: Double?
    let totalCost: Double?
    let taxes: Double?
    // Relationships
    let vendor: RemoteVendor
    let items: [RemoteInvoiceItem]

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case shipDate = "ship_date"
        case receiveDate = "receive_date"
        case status
        case storeID = "store_id"
        // Optional
        case invoiceNo = "invoice_no"
        case checkNo = "check_no"
        case credit
        case shipping
        case taxes
        case totalCost = "total_cost"
        // Relationships
        case items
        case vendor
    }
}

extension RemoteInvoice: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - InvoiceItem

struct RemoteInvoiceItem: Codable {

    // enum InvoiceItemStatus {}

    struct Item: Codable {
        let remoteID: Int
        let name: String
        private enum CodingKeys: String, CodingKey {
            case remoteID = "id"
            case name
        }
    }

    let remoteID: Int
    let item: Item
    let quantity: Int
    let unit: RemoteUnit
    let cost: Double?
    let discount: Double?
    let status: String

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case item
        case quantity
        case unit
        case cost
        case discount
        case status
    }
}

extension RemoteInvoiceItem: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}
