//
//  RemoteInventory.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/3/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation

// swiftlint:disable nesting

// MARK: - Inventory (New)

struct RemoteInventory: Codable {

    struct Category: Codable {
        let remoteID: Int
        let name: String
        let items: [RemoteNestedItem]

        private enum CodingKeys: String, CodingKey {
            case remoteID = "id"
            case name
            case items
        }
    }
    /*
    struct Item: Codable {

        struct RemoteItemPar: Codable {
            let par: Double
            let unitID: Int

            private enum CodingKeys: String, CodingKey {
                case par
                case unitID = "unit_id"
            }
        }

        let remoteID: Int
        let name: String
        let packSize: Int?
        let subSize: Double?
        // Foreign Keys
        let categoryID: Int?
        let inventoryUnitID: Int?
        let purchaseSubUnitID: Int?
        let purchaseUnitID: Int?
        let subUnitID: Int?
        // Relationships
        let par: RemoteItemPar?

        private enum CodingKeys: String, CodingKey {
            case remoteID = "id"
            case name
            case packSize = "pack_size"
            case subSize = "sub_size"
            case categoryID = "category_id"
            case inventoryUnitID = "inventory_unit_id"
            case purchaseSubUnitID = "purchase_sub_unit_id"
            case purchaseUnitID = "purchase_unit_id"
            case subUnitID = "sub_unit_id"
            case par
        }
    }
     */
    let remoteID: Int?
    //let date: Date
    let date: String
    let inventoryTypeID: Int?
    let storeID: Int
    // Relationships
    let categories: [Category]?
    //let items: [Item]?
    let items: [RemoteNestedItem]?
    let locations: [RemoteInventoryLocation]?

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case date
        case inventoryTypeID = "inventory_type_id"
        case storeID = "store_id"
        case categories
        case items
        case locations
    }
}

extension RemoteInventory: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID ?? 0) }
}

// MARK: - Inventory (New)

struct RemoteNewInventory: Codable {
    //let remoteID: Int?
    //let date: Date
    let date: String
    let inventoryTypeID: Int?
    let storeID: Int
    // Relationships
    let categories: [RemoteItemCategory]
    let items: [RemoteNestedItem]
    let locations: [RemoteInventoryLocation]

    private enum CodingKeys: String, CodingKey {
        //case remoteID = "id"
        case date
        case inventoryTypeID = "inventory_type_id"
        case storeID = "store_id"
        case categories
        case items
        case locations
    }
}

// MARK: - Inventory (Existing)

struct RemoteExistingInventory: Codable {
    let remoteID: Int
    let date: String
    let inventoryTypeId: Int?
    let storeId: Int
    let items: [RemoteInventoryItem]

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case date
        case inventoryTypeId = "inventory_type_id"
        case storeId = "store_id"
        case items
    }
}

extension RemoteExistingInventory: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - InventoryItem

struct RemoteInventoryItem: Codable {
    let remoteID: Int
    let quantity: Double
    let unitId: Int
    let item: RemoteNestedItem

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case item
        case quantity
        case unitId = "unit_id"
    }
}

extension RemoteInventoryItem: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - InventoryLocation

struct RemoteInventoryLocation: Codable {
    let remoteID: Int
    let name: String
    let locationType: RemoteLocationType
    //status
    // Relationships
    let categories: [RemoteLocationCategory]?
    let items: [Int]?

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case name
        case locationType = "loc_type"
        //status
        case categories
        case items
    }
}

extension RemoteInventoryLocation: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - InventoryLocationCategory

/// TODO: should we simply include `categoryID` to generate `items`?
struct RemoteLocationCategory: Codable {
    let remoteID: Int
    let name: String
    let items: [Int]

    private enum CodingKeys: String, CodingKey {
        // NOTE: remoteID refers to categoryID
        case remoteID = "id"
        case name
        case items
    }
}

extension RemoteLocationCategory: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}
