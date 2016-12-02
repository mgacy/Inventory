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

extension Item {

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON) {
        self.init(context: context)
        self.update(context: context, withJSON: json)
    }

    func update(context: NSManagedObjectContext, withJSON json: JSON) {

        // Properties
        if let remoteID = json["id"].int {
            self.remoteID = Int32(remoteID)
        }
        if let name = json["name"].string {
            self.name = name
        }
        if let packSize = json["pack_size"].int {
            self.packSize = Int16(packSize)
        }
        if let subSize = json["sub_size"].int {
            self.subSize = Int16(subSize)
        }

        //if let categoryID = json["category_id"].int {
        //    self.categoryID = Int32(categoryID)
        //}

        // TODO - implement:
        // active
        // shelfLife
        // sku
        // vendorItemID

        // Relationships
        // if let categoryID = json["category"]["id"].int { }
        if let vendorID = json["vendor"]["id"].int {

            if let vendor = context.fetchWithRemoteID(Vendor.self, withID: vendorID) {
                //print("Found Vendor: \(vendor)")
                self.vendor = vendor
            } else {
                let newVendor = Vendor(context: context)
                newVendor.remoteID = Int32(vendorID)
                
                if let vendorName = json["vendor"]["name"].string {
                    newVendor.name = vendorName
                }
            }

        }

        if let inventoryUnitID = json["inventory_unit"]["id"].int {
            self.inventoryUnit = context.fetchWithRemoteID(Unit.self, withID: inventoryUnitID)
        }
        if let purchaseUnitID = json["purchase_unit"]["id"].int {
            self.purchaseUnit = context.fetchWithRemoteID(Unit.self, withID: purchaseUnitID)
        }
        if let purchaseSubUnitID = json["purchase_sub_unit"]["id"].int {
            self.purchaseSubUnit = context.fetchWithRemoteID(Unit.self, withID: purchaseSubUnitID)
        }
        if let subUnitID = json["sub_unit"]["id"].int {
            self.subUnit = context.fetchWithRemoteID(Unit.self, withID: subUnitID)
        }

        // TODO - implement:
        // category
        // parUnit
        // store
    }

    // MARK: - Serialization

}
