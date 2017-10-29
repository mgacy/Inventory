//
//  OrderItemCellViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/29/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

//import Foundation
import UIKit

struct OrderItemCellViewModel: SubItemCellViewModelType {

    // MARK: - Properties

    // MARK: Private
    private let orderItem: OrderItem
    private let item: Item
    private var status: ItemStatus {
        return .normal
    }

    // MARK: Public
    var nameText: String { return item.name ?? "Error" }
    var nameColor: UIColor { return self.status.associatedColor }

    var packText: String { return item.packDisplay }

    var quantityColor: UIColor { return self.status.associatedColor }
    var quantityText: String {
        guard self.status != .inactive else {
            return ""
        }
        guard let quantity = orderItem.quantity else {
            return "Error"
        }
        return "\(quantity)"
    }

    var unitColor: UIColor { return self.status.associatedColor }
    var unitText: String {
        if self.status == .warning {
            return ""
        } else {
            return orderItem.orderUnit?.abbreviation ?? ""
        }
    }

    // MARK: - Lifecycle

    init?(forOrderItem orderItem: OrderItem) {
        self.orderItem = orderItem
        guard let item = orderItem.item else { return nil }
        self.item = item
    }

}
