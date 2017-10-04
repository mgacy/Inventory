//
//  RemoteItem.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation

// swiftlint:disable nesting

protocol RemoteRecord: Codable {
    associatedtype SyncIdentifierType: Hashable
    var syncIdentifier: SyncIdentifierType { get }
}

// MARK: - Item

struct RemoteItem: Codable {

    // Properties

    let active: Bool
    let remoteID: Int
    let name: String
    let packSize: Int?
    let shelfLife: Int?
    let sku: Int?
    let subSize: Double?
    let unitPrice: Double?
    let vendorItemId: Int?

    let category: RemoteItemCategory?
    let inventoryUnit: RemoteUnit?
    let purchaseSubUnit: RemoteUnit?
    let purchaseUnit: RemoteUnit?
    let subUnit: RemoteUnit?
    let vendor: RemoteVendor?

    private enum CodingKeys: String, CodingKey {
        case active
        case category
        case remoteID = "id"
        case inventoryUnit = "inventory_unit"
        case name
        case packSize = "pack_size"
        case purchaseSubUnit = "purchase_sub_unit"
        case purchaseUnit = "purchase_unit"
        case shelfLife = "shelf_life"
        case sku
        case subSize = "sub_size"
        case subUnit = "sub_unit"
        case unitPrice = "unit_price"
        case vendor
        case vendorItemId = "vendor_item_id"
    }
}

extension RemoteItem: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - ItemCategory

struct RemoteItemCategory: Codable {
    let remoteID: Int
    let name: String

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case name
    }
}

extension RemoteItemCategory: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - MenuItem

struct RemoteMenuItem: Codable {

    // Nested

    struct RemoteItem: Codable {
        let name: String
        let remoteID: Int
        private enum CodingKeys: String, CodingKey {
            case name
            case remoteID = "id"
        }
    }

    // Properties

    let categoryId: Int?
    let name: String
    let price: Double?
    let remoteID: Int
    let recipeItems: [RemoteRecipeItem]

    private enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case name
        case price
        case remoteID = "id"
        case recipeItems = "recipe_items"
    }
}

extension RemoteMenuItem: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - MenuItemCategory

struct RemoteMenuItemCategory: Codable {
    let remoteID: Int
    let name: String

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case name
    }
}

extension RemoteMenuItemCategory: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - RecipeItem

struct RemoteRecipeItem: Codable {

    // Nested

    struct Item: Codable {
        let name: String
        let remoteID: Int
        private enum CodingKeys: String, CodingKey {
            case name
            case remoteID = "id"
        }
    }

    struct MenuItem: Codable {
        let name: String
        let remoteID: Int
        private enum CodingKeys: String, CodingKey {
            case name
            case remoteID = "id"
        }
    }

    struct Unit: Codable {
        let abbreviation: String
        let remoteID: Int
        let name: String
        private enum CodingKeys: String, CodingKey {
            case abbreviation
            case remoteID = "id"
            case name
        }
    }

    //let remoteID: Int?
    let item: Item?
    let quantity: Double
    let menuItem: MenuItem?
    let unit: Unit

    private enum CodingKeys: String, CodingKey {
        //case remoteID
        case item
        case quantity
        case menuItem = "menu_item"
        case unit
    }
}

extension RemoteRecipeItem: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.item?.remoteID ?? 0) }
}

// MARK: - Store

struct RemoteStore: Codable {
    let remoteID: Int
    let name: String

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case name
    }
}

extension RemoteStore: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - Unit

struct RemoteUnit: Codable {

    // enum UnitType {}

    let abbreviation: String
    let remoteID: Int
    let name: String
    //let unitType: UnitType?

    private enum CodingKeys: String, CodingKey {
        case abbreviation
        case remoteID = "id"
        case name
    }
}

extension RemoteUnit: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - Vendor

struct RemoteVendor: Codable {
    let remoteID: Int
    let name: String
    let rep: RemoteRepresentative?

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case name
        case rep
    }
}

extension RemoteVendor: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - VendorRep

struct RemoteRepresentative: Codable {
    let email: String?
    let firstName: String?
    let remoteID: Int
    let lastName: String?
    let phone: String?
    private enum CodingKeys: String, CodingKey {
        case email
        case firstName = "first_name"
        case remoteID = "id"
        case lastName = "last_name"
        case phone
    }
}

extension RemoteRepresentative: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}
