//
//  OrderItemCellViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/29/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

struct OrderItemCellViewModel: SubItemCellViewModelType {

    // MARK: - Properties

    // MARK: Private
    private let orderItem: OrderItem
    private let item: Item
    private var status: ItemStatus {
        guard let quantity = orderItem.quantity else {
            return .warning
        }
        if quantity.doubleValue > 0.0 {
            return .normal
        } else {
            return .inactive
        }
    }

    // MARK: Public
    var nameText: String { return item.name ?? "Error" }
    var nameColor: UIColor { return self.status.associatedColor }

    var packText: String { return item.packDisplay }

    var quantityColor: UIColor { return self.status.associatedColor }
    var quantityText: String {
        /// TODO: simply use `switch status {}`?
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
        switch status {
        case .inactive:
            return ""
        case .normal:
            return orderItem.orderUnit?.abbreviation ?? ""
        case .pending:
            return orderItem.orderUnit?.abbreviation ?? ""
        case .warning:
            return ""
        }
    }

    // MARK: - Lifecycle

    init?(forOrderItem orderItem: OrderItem) {
        self.orderItem = orderItem
        guard let item = orderItem.item else { return nil }
        self.item = item
    }

}
