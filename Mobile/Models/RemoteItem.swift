//
//  RemoteItem.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation

protocol RemoteRecord: Codable {
    associatedtype SyncIdentifierType: Hashable
    var syncIdentifier: SyncIdentifierType { get }
}

// MARK: - Item

struct RemoteItem: Codable {

    // Properties

    let remoteID: Int
    let name: String
    let packSize: Int?
    let shelfLife: Int?
    let sku: Int?
    let subSize: Double?
    let unitPrice: Double?
    let vendorItemID: Int?
    let active: Bool

    let category: RemoteItemCategory?
    let inventoryUnit: RemoteUnit?
    let purchaseSubUnit: RemoteUnit?
    let purchaseUnit: RemoteUnit?
    let subUnit: RemoteUnit?
    let vendor: RemoteVendor?

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case name
        case active
        case category
        case inventoryUnit = "inventory_unit"
        case packSize = "pack_size"
        case purchaseSubUnit = "purchase_sub_unit"
        case purchaseUnit = "purchase_unit"
        case shelfLife = "shelf_life"
        case sku
        case subSize = "sub_size"
        case subUnit = "sub_unit"
        case unitPrice = "unit_price"
        case vendor
        case vendorItemID = "vendor_item_id"
    }
}

extension RemoteItem: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - Nested Item

struct RemoteNestedItem: Codable {
    let remoteID: Int
    let name: String
    //let category: RemoteItemCategory?

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case name
        //case category
    }
}

extension RemoteNestedItem: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - ItemCategory

struct RemoteItemCategory: Codable {
    let remoteID: Int
    let name: String
    let items: [RemoteNestedItem]?

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case name
        case items
    }
}

extension RemoteItemCategory: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - InventoryLocation (Non-Nested from /inventory_locations)

enum RemoteLocationType: String, Codable {
    case category
    case item
}

struct RemoteLocation: Codable {
    let remoteID: Int
    let name: String
    let storeId: Int

    let locationType: RemoteLocationType
    let categories: [RemoteItemCategory]
    let items: [RemoteNestedItem]

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case name
        case locationType = "loc_type"
        case categories
        case items
        case storeId = "store_id"
    }
}

extension RemoteLocation: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
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

// MARK: - Token

struct RemoteToken: Codable {
    let token: String
    let user: RemoteUser
}

// MARK: - Unit

struct RemoteUnit: Codable {
    /*
    enum RemoteUnitType: String, Codable {
        case count
        case volume
        case weight
        case collection
    }
    */
    let remoteID: Int
    let name: String
    let abbreviation: String
    //let unitType: UnitType?

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case name
        case abbreviation
    }
}

extension RemoteUnit: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}

// MARK: - User

struct RemoteUser: Codable {
    let remoteID: Int
    let username: String
    let email: String
    let defaultStore: RemoteStore
    let stores: [RemoteStore]

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case username
        case email
        case defaultStore = "default_store"
        case stores
    }
}

extension RemoteUser: RemoteRecord {
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
    let remoteID: Int
    let firstName: String?
    let lastName: String?
    let email: String?
    let phone: String?

    private enum CodingKeys: String, CodingKey {
        case remoteID = "id"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phone
    }
}

extension RemoteRepresentative: RemoteRecord {
    typealias SyncIdentifierType = Int32
    var syncIdentifier: SyncIdentifierType { return Int32(self.remoteID) }
}
