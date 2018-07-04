//
//  OrderLocItemViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/26/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

enum OrderLocItemParent {
    case location(OrderLocation)
    case category(OrderLocationCategory)
    //case remoteLocation(RemoteLocation)
    //case remoteCategory(RemoteItemCategory)

    var fetchPredicate: NSPredicate? {
        switch self {
        case .category(let category):
            return NSPredicate(format: "category == %@", category)
        case .location(let location):
            return NSPredicate(format: "location == %@", location)
        }
    }

}

struct OrderLocItemViewModel: AttachableViewModelType {

    // MARK: - Properties
    let frc: NSFetchedResultsController<OrderLocationItem>
    let navTitle: String
    //let selectedItem: Observable<OrderLocationItem>

    // CoreData
    /// NOTE: for InventoryLocItemViewModel we use both position and item.name
    private let sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Lifecycle

    init(dependency: Dependency, bindings: Bindings) {
        switch dependency.parent {
        case .category(let category):
            self.navTitle = category.name ?? "Error"
        case .location(let location):
            self.navTitle = location.name ?? "Error"
        }

        // FetchRequest
        let request: NSFetchRequest<OrderLocationItem> = OrderLocationItem.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = dependency.parent.fetchPredicate
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = dependency.dataManager.makeFetchedResultsController(fetchRequest: request)

        self.frc = frc
    }

    // MARK: - Swipe Actions

    func decrementOrder(forRowAtIndexPath indexPath: IndexPath) -> Bool {
        guard let orderItem = frc.object(at: indexPath).item, let currentQuantity = orderItem.quantity else {
            return false
        }
        //guard let currentQuantity = orderItem.quantity else {
        //    /// TODO: should we simply set .quantity to 0?
        //    //orderItem.quantity = 0.0
        //}
        if currentQuantity.doubleValue >= 1.0 {
            orderItem.quantity = NSNumber(value: currentQuantity.doubleValue - 1.0)
        } else {
            orderItem.quantity = 0.0
        }
        return true
    }

    func incrementOrder(forRowAtIndexPath indexPath: IndexPath) -> Bool {
        guard let orderItem = frc.object(at: indexPath).item, let currentQuantity: NSNumber = orderItem.quantity else {
            return false
        }
        //guard let currentQuantity: NSNumber = orderItem.quantity else {
        //    /// TODO: should we simply increment by 1 if .quantity is nil?
        //    //orderItem.quantity = 1.0
        //    return false
        //}
        orderItem.quantity = NSNumber(value: currentQuantity.doubleValue + 1.0)
        return true
    }

    func setOrderToPar(forRowAtIndexPath indexPath: IndexPath) -> Bool {
        guard let orderItem = frc.object(at: indexPath).item, let parUnit = orderItem.parUnit else {
            return false
        }
        /// TODO: should we return false if orderItem.par == 0?
        let newQuantity = orderItem.par.rounded(.awayFromZero)

        orderItem.quantity = newQuantity as NSNumber
        orderItem.orderUnit = parUnit
        return true
    }

    func setOrderToZero(forRowAtIndexPath indexPath: IndexPath) -> Bool {
        guard let orderItem = frc.object(at: indexPath).item else {
            return false
        }
        orderItem.quantity = 0
        return true
    }

    // MARK: - AttachableViewModelType

    struct Dependency {
        let dataManager: DataManager
        let parent: OrderLocItemParent
    }

    struct Bindings {
        let rowTaps: Observable<IndexPath>
    }

}
