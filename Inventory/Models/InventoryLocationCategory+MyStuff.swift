//
//  InventoryLocationCategory+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation

// MARK: - Computed Properties
extension InventoryLocationCategory {

    var status: InventoryStatus {

        var hasValue = false
        var missingValue = false

        guard let items = self.items else {
            // TODO: is this the correct way to handle this?
            return InventoryStatus.notStarted
        }

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
