//
//  Item+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/1/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension Item: Syncable {

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON) {
        self.init(context: context)
        self.update(context: context, withJSON: json)
    }

    public func update(context: NSManagedObjectContext, withJSON json: Any) {
        guard let json = json as? JSON else {
            log.error("\(#function) FAILED : SwiftyJSON"); return
        }

        // Properties
        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
        if let name = json["name"].string {
            self.name = name
        }
        if let packSize = json["pack_size"].int16 {
            self.packSize = packSize
        }
        if let subSize = json["sub_size"].int16 {
            self.subSize = subSize
        }

        /* 
         NOTE: not implemented:
         * active
         * shelfLife
         * sku
         * vendorItemID
         */

        // Relationships

        // Category
        if let categoryID = json["category"]["id"].int32, categoryID != self.category?.remoteID {

            // Try to fetch ItemCategory with categoryID; create one if it doesn't exist
            if let existingCategory = context.fetchWithRemoteID(ItemCategory.self, withID: categoryID) {
                self.category = existingCategory
            } else {
                /// TODO: should we really create a new ItemCategory if we don't have all its attributes?
                let newCategory = context.insertObject(ItemCategory.self)
                newCategory.remoteID = categoryID
                if let categoryName = json["category"]["name"].string {
                    newCategory.name = categoryName
                }
                self.category = newCategory
                log.verbose("Created ItemCategory: \(newCategory)")
            }
        }

        // Vendor
        if let vendorID = json["vendor"]["id"].int32, vendorID != self.vendor?.remoteID {

            // Try to fetch Vendor corresponding to vendorID; create one if it doesn't already exist
            if let vendor = context.fetchWithRemoteID(Vendor.self, withID: vendorID) {
                self.vendor = vendor
            } else {
                /// TODO: should we really create a new Vendor if we don't have all its attributes?
                let newVendor = context.insertObject(Vendor.self)
                newVendor.remoteID = vendorID
                if let vendorName = json["vendor"]["name"].string {
                    newVendor.name = vendorName
                }
                self.vendor = newVendor
                log.verbose("Created Vendor: \(newVendor)")
            }
        }

        /// NOTE: Unit relationships are handled by updateUnits to minimize fetch requests on sync
        /// TODO: should we do the same with other relationships?
        /*
         Here, we expect to have all the info necessary to create new objects if they don't already exist (whereas we do not in
         the case of the various Units
         */

        /* 
         NOTE - not implemented:
         * parUnit
         * store
         */
    }

    public func updateUnits(withJSON json: JSON, unitDict: [Int32: Unit]) {
        if let
            inventoryUnitID = json["inventory_unit"]["id"].int32,
            inventoryUnitID != self.inventoryUnit?.remoteID {
            self.inventoryUnit = unitDict[inventoryUnitID]
        }

        if let
            purchaseUnitID = json["purchase_unit"]["id"].int32,
            purchaseUnitID != self.purchaseUnit?.remoteID {
            self.purchaseUnit = unitDict[purchaseUnitID]
        }

        if let
            purchaseSubUnitID = json["purchase_sub_unit"]["id"].int32,
            purchaseSubUnitID != self.purchaseSubUnit?.remoteID {
            self.purchaseSubUnit = unitDict[purchaseSubUnitID]
        }

        if let
            subUnitID = json["sub_unit"]["id"].int32,
            subUnitID != self.subUnit?.remoteID {
            self.subUnit = unitDict[subUnitID]
        }
    }

    // MARK: - Serialization

}

extension Item {

    /// TODO: move this to a view model
    var packDisplay: String {
        return "\(self.packSize) x \(self.subSize) \(self.subUnit?.abbreviation ?? " ")"
    }

}
