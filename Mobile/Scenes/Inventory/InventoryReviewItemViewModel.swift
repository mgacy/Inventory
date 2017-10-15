//
//  InventoryReviewItemViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/15/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

struct InventoryReviewItemViewModel: SubItemCellViewModelType {
    private var inventoryItem: InventoryItem
    private var item: Item

    private let status: ItemStatus = .normal
    //private var status: ItemStatus { switch inventoryItem.status {} }

    private var quantity: Double {
        return inventoryItem.items?.reduce(0.0, { runningTotal, current in
            let inventoryItem = current as? InventoryLocationItem
            let quantity = inventoryItem?.quantity?.doubleValue ?? 0.0
            //return total! + quantity
            return (runningTotal ?? 0.0) + quantity
        }) ?? 0.0
    }

    // MARK: - Public

    var nameColor: UIColor {
        return self.status.associatedColor
    }
    var nameText: String {
        return item.name ?? "Error"
    }

    //var packColor: UIColor { return .lightGray }
    var packText: String { return item.packDisplay }

    var quantityColor: UIColor { return self.status.associatedColor }
    var quantityText: String { return "\(quantity)" }

    var unitColor: UIColor { return self.status.associatedColor }
    var unitText: String {
        return item.inventoryUnit?.abbreviation ?? ""
        /*
        if Double(quantity) > 0.0 {
            return item.inventoryUnit?.abbreviation ?? ""
        } else {
            return ""
        }
         */
    }

    // MARK: - Lifecycle

    init(forInventoryItem inventoryItem: InventoryItem) {
        self.inventoryItem = inventoryItem
        guard let item = inventoryItem.item else {
            /// TODO: is a fatalError too extreme a response?
            fatalError("Unable to get Item to configure cell")
        }
        self.item = item
    }

}
