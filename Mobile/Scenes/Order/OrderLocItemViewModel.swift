//
//  OrderLocItemViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/26/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxCocoa
import RxSwift

enum OrderLocItemParent {
    case location(RemoteLocation)
    case category(RemoteItemCategory)
}

struct OrderLocItemViewModel {

    // MARK: - Properties
    let navTitle: String
    let items: Observable<[OrderItem]>
    let orderItems: [OrderItem]
    private let dataManager: DataManager
    private let parent: OrderLocItemParent
    private let factory: OrderLocationFactory

    // MARK: - Lifecycle

    init(dataManager: DataManager, parent: OrderLocItemParent, factory: OrderLocationFactory) {
        self.dataManager = dataManager
        self.parent = parent
        self.factory = factory

        switch parent {
        case .category(let category):
            self.navTitle = category.name
            self.orderItems = factory.getOrderItems(forCategoryType: category) ?? []
            self.items = Observable.just(orderItems)
        case .location(let location):
            self.navTitle = location.name
            self.orderItems = factory.getOrderItems(forItemType: location) ?? []
            self.items = Observable.just(orderItems)
        }
    }

    // MARK: - Swipe Actions

    func decrementOrder(forRowAtIndexPath indexPath: IndexPath) -> Bool {
        let orderItem = orderItems[indexPath.row]
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

    func incrementOrder(forRowAtIndexPath indexPath: IndexPath) -> Bool {
        let orderItem = orderItems[indexPath.row]
        guard let currentQuantity: NSNumber = orderItem.quantity else {
            /// TODO: should we simply increment by 1 if .quantity is nil?
            //orderItem.quantity = 1.0
            return false
        }
        orderItem.quantity = NSNumber(value: currentQuantity.doubleValue + 1.0)
        return true
    }

    func setOrderToPar(forRowAtIndexPath indexPath: IndexPath) -> Bool {
        let orderItem = orderItems[indexPath.row]
        guard let parUnit = orderItem.parUnit else {
            return false
        }
        /// TODO: should we return false if orderItem.par == 0?
        let newQuantity = orderItem.par.rounded(.awayFromZero)

        orderItem.quantity = newQuantity as NSNumber
        orderItem.orderUnit = parUnit
        return true
    }

    func setOrderToZero(forRowAtIndexPath indexPath: IndexPath) -> Bool {
        let orderItem = orderItems[indexPath.row]
        orderItem.quantity = 0
        return true
    }

}
