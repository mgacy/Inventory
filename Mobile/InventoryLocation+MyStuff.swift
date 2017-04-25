//
//  InventoryLocation+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

enum InventoryLocationType {
    case category
    case item
}

// TODO: rename to InventoryLocationStatus?
enum InventoryStatus {
    case notStarted
    case incomplete
    case complete
}

extension InventoryLocation {

    // MARK: - Computed Properties

    var status: InventoryStatus? {
        switch self.locationType {
        case "category"?:
            return self.statusForCategory
        case "item"?:
            return self.statusForLocation
        default:
            fatalError("Unrecognied locationType")
        }
    }

    private var statusForCategory: InventoryStatus {
        guard let categories = self.categories else {
            /// TODO: is this the correct way to handle this?
            return InventoryStatus.notStarted
        }

        var hasCompleted = false
        var hasIncompleted = false
        var hasNotStarted = false

        for category in categories {
            switch (category as! InventoryLocationCategory).status {
            case InventoryStatus.complete:
                hasCompleted = true
                if hasIncompleted || hasNotStarted {
                    return InventoryStatus.incomplete
                }
            case InventoryStatus.incomplete:
                hasIncompleted = true
                if hasCompleted {
                    return InventoryStatus.incomplete
                }
            case InventoryStatus.notStarted:
                hasNotStarted = true
                if hasCompleted || hasIncompleted {
                    return InventoryStatus.incomplete
                }
            }
        }

        // If we made it through all the categories ...
        var status: InventoryStatus
        switch hasCompleted {
        case true:
            if hasIncompleted || hasNotStarted {
                status = InventoryStatus.incomplete
            } else {
                status = InventoryStatus.complete
            }
        case false:
            status = InventoryStatus.notStarted
        }

        return status
    }

    private var statusForLocation: InventoryStatus {
        guard let items = self.items else {
            /// TODO: is this the correct way to handle this?
            return InventoryStatus.notStarted
        }

        var hasValue = false
        var missingValue = false

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
                     inventory: Inventory) {
        self.init(context: context)

        // Properties
        if let name = json["name"].string {
            self.name = name
        }
        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
        if let locationType = json["loc_type"].string {
            self.locationType = locationType
        }

        // Relationship
        self.inventory = inventory

        // Add children based on Location type
        switch self.locationType {
        case "item"?:
            if let itemIDs = json["items"].array {
                addLocationItems(context: context, json: itemIDs)
            }
        case "category"?:
            if let categories = json["categories"].array {
                addLocationCategories(context: context, json: categories, location: self)
            }
        default:
            fatalError("Unrecognied locationType")
        }
    }

    convenience init(context: NSManagedObjectContext, name: String, remoteID: Int, type: InventoryLocationType, inventory: Inventory) {
        self.init(context: context)

        // Properties (A)
        //if let _name = name { self.name = _name}
        //if let _remoteID = remoteID {self.remoteID = _remoteID }

        // Properties (B)
        self.name = name
        self.remoteID = Int32(remoteID)
        self.locationType = "\(type)"

        // Relationships
        self.inventory = inventory
    }

    // MARK: - Handle New

    private func addLocationCategories(context: NSManagedObjectContext, json: [JSON],
                               location: InventoryLocation) {
        for (position, category) in json.enumerated() {
            _ = InventoryLocationCategory(context: context, json: category, location: location, position: position + 1)
            /*
            let category = InventoryLocationCategory(context: context, json: object, location: location)

            // LocationItems
            if let itemIDs = object["items"].array {
                //addLocationItems(category: &category, json: itemIDs)

                for itemID in itemIDs {
                    if let id = itemID.int {
                        _ = InventoryLocationItem(context: context, itemID: id, category: category)
                    }
                }
            }
            */
        }
    }

    private func addLocationItems(context: NSManagedObjectContext, json: [JSON]) {
        for (position, itemID) in json.enumerated() {
            if let itemID = itemID.int {
                _ = InventoryLocationItem(context: context, itemID: itemID, location: self,
                                          position: position + 1)
            }
        }
    }

    // MARK: - Handle existing

    func doStuff(context: NSManagedObjectContext, json: JSON, location: InventoryLocation,
                 locationItem: InventoryLocationItem) {

        // Handle ItemCategory and InventoryLocationCategory
        guard let categoryName = json["item"]["category"]["name"].string else { return }
        guard let id = json["item"]["category"]["id"].int else { return }

        // Try to fetch corresponding InventoryLocationCategory
        if let locationCategory = fetchCategory(context: context, id: id) {
            locationItem.category = locationCategory

        } else {
            // If one does not already exist, create one
            /// TODO: handle position
            let locationCategory = InventoryLocationCategory(context: context, id: id,
                                                             name: categoryName, location: self)
            locationCategory.location = location
            locationItem.category = locationCategory
        }

    }

    private func fetchCategory(context: NSManagedObjectContext, id: Int) -> InventoryLocationCategory? {
        // TODO: add check for self.locationType?
        let _id = Int32(id)
        if let locationCategory = self.categories?.filter({ ($0 as! InventoryLocationCategory).categoryID == _id }).first {
            return locationCategory as? InventoryLocationCategory
        } else {
            return nil
        }
    }

}
