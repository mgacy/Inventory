//
//  InventoryItemTableViewCell.swift
//  Mobile
//
//  Created by Mathew Gacy on 4/24/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

class InventoryItemTableViewCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detail: UILabel!
}

extension InventoryItemTableViewCell {
    func configure(for locationItem: InventoryLocationItem) {
        guard
            let inventoryItem = locationItem.item,
            let item = inventoryItem.item else {
                fatalError("Unable to get Item to configure cell")
        }

        label.text = item.name
        detail.textColor = UIColor.lightGray

        /// TODO: clean this ugly mess up
        if let quantity = locationItem.quantity {
            label.textColor = UIColor.black

            if
                let inventoryUnit = item.inventoryUnit,
                let abbreviation = inventoryUnit.abbreviation
            {
                detail.text = "\(quantity) \(abbreviation)"
            } else {
                detail.text = "\(quantity)"
            }

        } else {
            label.textColor = UIColor.lightGray
            //detail.text = nil
            detail.text = " "
        }

    }
}
