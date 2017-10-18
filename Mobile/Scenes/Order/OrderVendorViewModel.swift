//
//  OrderVendorViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/11/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

enum OrderVendorSegue {
    case back
    case item(Order)
}

class OrderVendorViewModel {

    // MARK: - Properties

    //private let dataManager: DataManager
    let dataManager: DataManager
    private let parentObject: OrderCollection

    // CoreData
    private let filter: NSPredicate?
    private let sortDescriptors = [NSSortDescriptor(key: "vendor.name", ascending: true)]
    private let cacheName: String? = nil
    private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input
    let refresh: AnyObserver<Void>
    let confirmComplete: AnyObserver<Void>

    // MARK: - Output
    let frc: NSFetchedResultsController<Order>
    let hasRefreshed: Driver<Bool>
    let showAlert: Driver<Void>
    let showNext: Observable<OrderVendorSegue>
    //let showNext: Driver<OrderVendorSegue>

    // MARK: - Lifecycle

    // swiftlint:disable:next function_body_length
    init(dataManager: DataManager, parentObject: OrderCollection, rowTaps: Observable<Order>, completeTaps: Observable<Void>) {
        self.dataManager = dataManager
        self.parentObject = parentObject

        // Refresh
        let _refresh = PublishSubject<Void>()
        self.refresh = _refresh.asObserver()
        self.hasRefreshed = _refresh.asObservable()
            .map { _ in
                parentObject.updateStatus()
                return true
            }
            .asDriver(onErrorJustReturn: false)

        // Prompt Confirmation
        let _confirmComplete = PublishSubject<Void>()
        self.confirmComplete = _confirmComplete.asObserver()

        // FetchRequest
        self.filter = NSPredicate(format: "collection == %@", parentObject)
        let request: NSFetchRequest<Order> = Order.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false

        //let managedObjectContext = dataManager.managedObjectContext
        self.frc = NSFetchedResultsController(fetchRequest: request,
                                              managedObjectContext: dataManager.managedObjectContext,
                                              sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)

        // Check collection status
        let safeToComplete = completeTaps
            .map { _ in
                return OrderVendorViewModel.checkStatusIsSafe(forCollection: parentObject)
            }

        /// TODO: rename `confirmUnsafeComplete`?
        // If there are pending orders we want to warn the user about marking this collection as completed
        self.showAlert = safeToComplete
            .filter { !$0 }
            .map { _ in }
            .asDriver(onErrorJustReturn: ())

        // Navigation

        // Update Status
        let backTransition: Observable<OrderVendorSegue> = Observable.of(
                _confirmComplete.asObservable(),
                safeToComplete.filter { $0 }.map { _ in }
            )
            .merge()
            .map { _ -> OrderVendorSegue in
                log.debug("Going back ...")
                /// TODO: refresh OrderDateViewController
                parentObject.uploaded = true
                return OrderVendorSegue.back
            }

        let orderTransition = rowTaps
            .map { order -> OrderVendorSegue in
                log.debug("Selected Order: \(order)")
                return OrderVendorSegue.item(order)
            }

        self.showNext = Observable.of(backTransition, orderTransition)
            .merge()
            //.asDriver(onErrorJustReturn: .back)
    }

    private static func checkStatusIsSafe(forCollection collection: OrderCollection) -> Bool {
        guard let orders = collection.orders else {
            return true
        }

        //var hasEmpty = false
        var hasPending = false

        for order in orders {
            if let status = (order as? Order)?.status {
                switch status {
                //case OrderStatus.empty.rawValue:
                //    hasEmpty = true
                case OrderStatus.pending.rawValue:
                    hasPending = true
                //case OrderStatus.placed.rawValue:
                //case OrderStatus.uploaded.rawValue:
                default:
                    /// TODO: use another color for values that aren't captured above
                    continue
                }
            }
        }

        if hasPending {
            return false
        } else {
            return true
        }
    }

}
