//
//  InventoryReviewViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/11/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

struct InventoryReviewViewModel {

    // MARK: Properties

    private let dataManager: DataManager
    private let parentObject: Inventory

    // CoreData
    private let filter: NSPredicate?
    private let sortDescriptors = [NSSortDescriptor(key: "item.name", ascending: true)]
    private let cacheName: String? = nil
    private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input
    //let refresh: AnyObserver<Void>
    //let editTaps: AnyObserver<Void>
    //let rowTaps: AnyObserver<InvoiceCollection>

    // MARK: - Output
    let frc: NSFetchedResultsController<InventoryItem>
    let isRefreshing: Driver<Bool>
    //let hasRefreshed: Driver<Bool>
    let showTable: Driver<Bool>
    let showSelection: Observable<InventoryItem>
    //let errorMessages: Driver<String>

    init(dataManager: DataManager, parentObject: Inventory, rowTaps: Observable<InventoryItem>) {
        self.dataManager = dataManager
        self.parentObject = parentObject

        // Activity
        let isRefreshing = ActivityIndicator()
        self.isRefreshing = isRefreshing.asDriver()

        self.showTable = dataManager.refreshInventory(parentObject)
            .trackActivity(isRefreshing)
            //.dematerialize()
            .elements()
            .map { inventory -> Bool in
                log.debug("\(#function) : \(inventory)")
                if let itemCount = inventory.items?.count {
                    return itemCount > 0
                }
                return false
            }
            .startWith(false)
            .asDriver(onErrorJustReturn: false)

        // Selection

        // Navigation
        showSelection = rowTaps
            //.throttle(0.5, scheduler: MainScheduler.instance)
            .map { selection in
                log.debug("Tapped: \(selection)")
                return selection
            }

        // Errors
        //errorMessages =

        // FetchRequest
        self.filter = NSPredicate(format: "inventory == %@", parentObject)
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false

        let managedObjectContext = dataManager.managedObjectContext
        self.frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext,
                                              sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)

    }

}
