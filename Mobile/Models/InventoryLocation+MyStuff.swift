//
//  InventoryLocation+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData

enum InventoryLocationType: String {
    case category
    case item
}

// TODO: rename to InventoryLocationStatus?
enum InventoryStatus {
    case notStarted
    case incomplete
    case complete
}

// MARK: - NewSyncable

extension InventoryLocation: NewSyncable {
    typealias RemoteType = RemoteInventoryLocation
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: Int32 { return self.remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        remoteID = record.syncIdentifier
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        //remoteID
        name = record.name
        //locationType

        // Relationships
        //categories?
        //items?
    }

}

// MARK: - Computed Properties
extension InventoryLocation {

    var status: InventoryStatus? {
        switch self.locationType {
        case "category"?:
            return self.statusForCategory
        case "item"?:
            return self.statusForLocation
        default:
            fatalError("Unrecognied locationType: \(String(describing: self.locationType))")
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
            // swiftlint:disable:next force_cast
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
            switch hasIncompleted {
            case true:
                status = .incomplete
            case false:
                status = .notStarted
            }
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
            // swiftlint:disable:next force_cast
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

}
