//
//  OrderItemPhoneCellViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/29/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

struct OrderItemPhoneCellViewModel: SubItemCellViewModelType {

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

// MARK: - OrderLocItemActionable

extension OrderItemPhoneCellViewModel {

    // MARK: - Swipe Actions

    func decrementOrder() -> Bool {
        guard let currentQuantity = orderItem.quantity else {
            /// TODO: should we simply set .quantity to 0?
            //orderItem.quantity = 0.0
            return false
        }

        if currentQuantity.doubleValue >= 1.0 {
            orderItem.quantity = NSNumber(value: currentQuantity.doubleValue - 1.0)
        } else {
            orderItem.quantity = 0.0
        }
        return true
    }

    func incrementOrder() -> Bool {
        guard let currentQuantity: NSNumber = orderItem.quantity else {
            /// TODO: should we simply increment by 1 if .quantity is nil?
            //orderItem.quantity = 1.0
            return false
        }
        orderItem.quantity = NSNumber(value: currentQuantity.doubleValue + 1.0)
        return true
    }

    func setOrderToPar() -> Bool {
        guard let parUnit = orderItem.parUnit else {
            return false
        }
        /// TODO: should we return false if orderItem.par == 0?
        let newQuantity = orderItem.par.rounded(.awayFromZero)

        orderItem.quantity = newQuantity as NSNumber
        orderItem.orderUnit = parUnit
        return true
    }

    func setOrderToZero() -> Bool {
        orderItem.quantity = 0
        return true
    }

}
