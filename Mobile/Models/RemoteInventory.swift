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

        struct CategoryItem: Codable {
            let id: Int
            let name: String
        }

        let id: Int
        let name: String
        let items: [CategoryItem]
    }

    struct Item: Codable {

        // swiftlint:disable:next type_name
        struct Par: Codable {
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
        let par: Par?

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

    let remoteID: Int?
    //let date: Date
    let date: String
    let inventoryTypeID: Int?
    let storeID: Int
    // Relationships
    let categories: [Category]?
    let items: [Item]?
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

// MARK: - InventoryLocation

struct RemoteInventoryLocation: Codable {
    let remoteID: Int
    let name: String
    let locType: String
    // Relationships
    let categories: [RemoteLocationCategory]?
    let items: [Int]?

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case name
        case locType = "loc_type"
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
        case remoteID = "id"
        case name
        case items
    }
}

extension RemoteLocationCategory: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}
