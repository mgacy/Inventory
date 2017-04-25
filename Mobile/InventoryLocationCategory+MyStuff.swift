//
//  InventoryLocationCategory+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension InventoryLocationCategory {

    // MARK: - Computed Properties

    var status: InventoryStatus {

        var hasValue = false
        var missingValue = false

        guard let items = self.items else {
            /// TODO: is this the correct way to handle this?
            return InventoryStatus.notStarted
        }

        for item in items {
            if (item as! InventoryLocationItem).quantity != nil {
                hasValue = true
                if missingValue {
                    return InventoryStatus.incomplete
                }
            } else {
                missingValue = true
                if hasValue {
                    return InventoryStatus.incomplete
                }
            }
        }

        // If we made it through all the items ...
        var status: InventoryStatus
        switch hasValue {
        case true:
            if missingValue {
                status = InventoryStatus.incomplete
            } else {
                status = InventoryStatus.complete
            }
        case false:
            status = InventoryStatus.notStarted
        }
        return status
    }

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON,
                     location: InventoryLocation, position: Int) {
        self.init(context: context)

        // Properties
        self.position = Int16(position)
        if let name = json["name"].string {
            self.name = name
        }
        if let categoryID = json["id"].int32 {
            self.categoryID = categoryID
        }

        // Relationship
        self.location = location

        // LocationItems
        if let itemIDs = json["items"].array {
            for itemID in itemIDs {
                if let id = itemID.int {
                    _ = InventoryLocationItem(context: context, itemID: id, category: self)
                }
            }
        }
    }

    convenience init(context: NSManagedObjectContext, id: Int, name: String,
                     location: InventoryLocation) {
        self.init(context: context)

        // Properties
        self.categoryID = Int32(id)
        self.name = name

        // Relationship
        self.location = location
    }
}
