//
//  InventoryLocationItemViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 7/6/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
//import Foundation

struct InventoryLocationItemViewModel: SubItemCellViewModel {
    private var locationItem: InventoryLocationItem
    private var item: Item
    private var status: ItemStatus {
        guard locationItem.quantity != nil else {
            return .inactive
        }
        return .normal
    }

    // MARK: - Public

    var nameColor: UIColor { return self.status.associatedColor }
    var nameText: String {
        guard let name = item.name else {
            return "Error"
        }
        return name
    }

    //var packColor: UIColor { return .lightGray }
    var packText: String { return item.packDisplay }

    var quantityColor: UIColor { return self.status.associatedColor }
    var quantityText: String {
        guard self.status != .inactive else {
            return ""
        }
        guard let quantity = locationItem.quantity else {
            return "Error"
        }
        return "\(quantity)"
    }

    var unitColor: UIColor { return self.status.associatedColor }
    var unitText: String {
        if self.status == .warning {
            return ""
        } else {
            return item.inventoryUnit?.abbreviation ?? ""
        }
    }

    // MARK: - Lifecycle

    init(forLocationItem locationItem: InventoryLocationItem) {
        self.locationItem = locationItem
        guard let inventoryItem = locationItem.item else {
            fatalError("Unable to get InventoryItem to configure cell")
        }
        guard let item = inventoryItem.item else {
            fatalError("Unable to get Item to configure cell")
        }
        self.item = item
    }

}
