//
//  RemoteInventory.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/3/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation

// swiftlint:disable nesting

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
        let categoryID: Int
        let packSize: Int
        let par: Par
        let subSize: Double
        let subUnitID: Int
        let inventoryUnitID: Int
        let purchaseUnitID: Int
        let purchaseSubUnitID: Int

        private enum CodingKeys: String, CodingKey {
            case remoteID = "id"
            case name
            case categoryID = "category_id"
            case packSize = "pack_size"
            case par
            case subSize = "sub_size"
            case subUnitID = "sub_unit_id"
            case inventoryUnitID = "inventory_unit_id"
            case purchaseUnitID = "purchase_unit_id"
            case purchaseSubUnitID = "purchase_sub_unit_id"
        }
    }

    let remoteID: Int
    //let date: Date
    let date: String
    let inventoryTypeID: Int?
    let storeID: Int
    let items: [Item]?
    let categories: [Category]?
    let locations: [RemoteInventoryLocation]?

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case date
        case inventoryTypeID = "inventory_type_id"
        case storeID = "store_id"
        case items
        case categories
        case locations
    }
}

extension RemoteInventory: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - InventoryLocation

struct RemoteInventoryLocation: Codable {

    // Nested

    struct LocationCategory: Codable {
        let id: Int
        let name: String
        let items: [Int]
    }

    let remoteID: Int
    let name: String
    let locType: String
    let categories: [LocationCategory]?
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
