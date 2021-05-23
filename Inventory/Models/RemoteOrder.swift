//
//  RemoteOrder.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/4/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation

// MARK: - OrderCollection

struct RemoteOrderCollection: Codable {
    let date: String
    let inventoryId: Int?
    let storeID: Int
    //let status: String
    // Relationships
    let orders: [RemoteOrder]?

    private enum CodingKeys: String, CodingKey {
        case date
        case inventoryId = "inventory_id"
        case storeID = "store_id"
        //case status
        case orders
    }
}

extension RemoteOrderCollection: RemoteRecord {
    typealias SyncIdentifierType = Date
    var syncIdentifier: SyncIdentifierType { return date.toBasicDate() ?? Date() }
}

// MARK: - Order

struct RemoteOrder: Codable {
    let remoteID: Int?
    let date: String
    //let status: String
    let cost: Double?
    // Relationships
    let vendor: RemoteVendor
    let items: [RemoteOrderItem]

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case date
        //case status
        case cost
        case items
        case vendor
    }
}

extension RemoteOrder: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID ?? 0) }
}

// MARK: - OrderItem

struct RemoteOrderItem: Codable {

    struct Item: Codable {
        let remoteID: Int
        let name: String
        let packSize: Int?
        // Relationships
        let category: RemoteItemCategory?
        let purchaseUnit: RemoteUnit?
        let purchaseSubUnit: RemoteUnit?
        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case remoteID = "id"
            case name
            case category
            case packSize = "pack_size"
            case purchaseSubUnit = "purchase_sub_unit"
            case purchaseUnit = "purchase_unit"
        }
    }

    let remoteID: Int?
    let inventory: Double?
    let minOrder: Double?
    let minOrderUnitId: Int?
    let par: Double?
    let parUnitId: Int?
    let quantity: Double?
    //let unitId: Int
    //let usageHistory: Any?
    // Relationships
    let item: Item
    let unit: RemoteUnit

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case inventory
        case minOrder = "min_order"
        case minOrderUnitId = "min_order_unit_id"
        case par
        case parUnitId = "par_unit_id"
        case quantity
        //case unitId = "unit_id"
        //case usageHistory = "usage_history"
        case item
        case unit
    }
}

extension RemoteOrderItem: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID ?? 0) }
}
