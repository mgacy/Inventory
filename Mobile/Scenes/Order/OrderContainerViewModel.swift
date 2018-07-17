//
//  OrderContainerViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class OrderContainerViewModel {

    // MARK: - Properties

    private let dataManager: DataManager
    private let parentObject: OrderCollection

    // CoreData

    // MARK: - Input
    let confirmComplete: AnyObserver<Void>

    // MARK: - Output
    let showAlert: Driver<Void>
    let popView: Observable<Void>

    // MARK: - Lifecycle

    init(dataManager: DataManager, parentObject: OrderCollection, completeTaps: Observable<Void>) {
        self.dataManager = dataManager
        self.parentObject = parentObject

        // Prompt Confirmation
        let _confirmComplete = PublishSubject<Void>()
        self.confirmComplete = _confirmComplete.asObserver()

        // Check collection status
        // We have to call `checkStatusIsSafe(forCollection:)` as a static function since we can't call `self` before
        // initializing all properties
        let safeToComplete = completeTaps
            .map { _ in
                return OrderContainerViewModel.checkStatusIsSafe(forCollection: parentObject)
            }

        /// TODO: rename `confirmUnsafeComplete`?
        // If there are pending orders we want to warn the user about marking this collection as completed
        self.showAlert = safeToComplete
            .filter { !$0 }
            .map { _ in }
            .asDriver(onErrorJustReturn: ())

        // Update Status
        self.popView = Observable.of(_confirmComplete.asObservable(), safeToComplete.filter { $0 }.map { _ in })
            .merge()
            .map { _ in
                //log.debug("Going back ...")
                /// TODO: refresh OrderDateViewController
                parentObject.uploaded = true
                return
            }
            //.asDriver(onErrorJustReturn: ())
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
