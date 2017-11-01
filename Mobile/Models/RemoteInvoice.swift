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

    // enum InvoiceCollectionStatus: String, Codable {}

    //let date: Date
    let date: String
    let status: String
    let storeID: Int
    let invoices: [RemoteInvoice]?

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
    /*
    enum RemoteInvoiceStatus: String, Codable {
        case completed
        case pending
        case rejected
    }
    */
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
    /*
    enum RemoteInvoiceItemStatus: String, Codable {
        case pending
        case received
        case damaged
        case outOfStock
        case promo
        case substitute
        case wrongItem
    }
    */
    let remoteID: Int
    /// TODO: should quantity be an Int or Double?
    let quantity: Double
    let status: String
    // Optional
    let cost: Double?
    let discount: Double?
    // Relationships
    let item: RemoteNestedItem
    let unit: RemoteUnit

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case quantity
        case status
        case cost
        case discount
        case item
        case unit
    }
}

extension RemoteInvoiceItem: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}
