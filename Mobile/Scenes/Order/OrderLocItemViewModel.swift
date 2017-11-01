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

    /// TODO: make private
    let dataManager: DataManager
    let parent: OrderLocItemParent
    let factory: OrderLocationFactory
    let orderItems: [OrderItem]

    // MARK: - Input

    // MARK: - Output
    let navTitle: String
    let items: Observable<[OrderItem]>

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

}
