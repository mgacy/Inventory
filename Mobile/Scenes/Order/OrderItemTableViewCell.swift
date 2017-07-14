//
//  OrderItemTableViewCell.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/22/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

class OrderItemTableViewCell: UITableViewCell {
    @IBOutlet weak var nameTextLabel: UILabel!
    @IBOutlet weak var packTextLabel: UILabel!
    @IBOutlet weak var quantityTextLabel: UILabel!
    @IBOutlet weak var unitTextLabel: UILabel!
}

extension OrderItemTableViewCell {
    func configure(forOrderItem orderItem: OrderItem) {
        guard let item = orderItem.item else {
            fatalError("Unable to get Item to configure cell")
        }

        nameTextLabel.text = item.name
        packTextLabel.text = item.packDisplay
        packTextLabel.textColor = UIColor.lightGray

        guard let quantity = orderItem.quantity else {
            // Highlight OrderItems w/o order
            nameTextLabel.textColor = ColorPalette.redColor
            quantityTextLabel.text = "?"
            quantityTextLabel.textColor = ColorPalette.redColor
            unitTextLabel.text = ""
            unitTextLabel.textColor = ColorPalette.redColor
            return
        }
        if Double(quantity) > 0.0 {
            nameTextLabel.textColor = UIColor.black
            quantityTextLabel.text = "\(quantity)"
            quantityTextLabel.textColor =  UIColor.black
            unitTextLabel.text = orderItem.orderUnit?.abbreviation ?? ""
            unitTextLabel.textColor = UIColor.black

        } else {
            nameTextLabel.textColor = UIColor.lightGray
            /// TODO: should I even bother displaying quantity?
            quantityTextLabel.text = "\(quantity)"
            quantityTextLabel.textColor = UIColor.lightGray
            unitTextLabel.text = orderItem.orderUnit?.abbreviation ?? ""
            unitTextLabel.textColor = UIColor.lightGray
        }
        /// TODO: add warning color if quantity < suggested (excluding when par = 1 and suggested < 0.x)

        /*
        // FROM InventoryItemTableViewCell
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
        */
    }

}
