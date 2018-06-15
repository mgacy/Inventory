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
import RxSwiftExt

struct InventoryReviewViewModel: AttachableViewModelType {

    // MARK: Properties

    let frc: NSFetchedResultsController<InventoryItem>
    let isRefreshing: Driver<Bool>
    //let hasRefreshed: Driver<Bool>
    let showTable: Driver<Bool>
    //let messageLabel: Driver<String>
    let errorMessages: Driver<String>
    let showSelection: Observable<InventoryItem>

    private let dataManager: DataManager
    private let parentObject: Inventory

    // CoreData
    private let filter: NSPredicate?
    private let sortDescriptors = [NSSortDescriptor(key: "item.name", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    init(dependency: Dependency, bindings: Bindings) {
        self.dataManager = dependency.dataManager
        self.parentObject = dependency.parent

        // Activity
        let isRefreshing = ActivityIndicator()
        self.isRefreshing = isRefreshing.asDriver()

        let refreshResults = dataManager.refreshInventory(dependency.parent)
            .trackActivity(isRefreshing)
            .share()

        //self.hasRefreshed = refreshResults

        self.showTable = refreshResults
            .elements()
            .map { inventory -> Bool in
                //log.debug("\(#function) : \(inventory)")
                if let itemCount = inventory.items?.count {
                    return itemCount > 0
                }
                return false
            }
            .startWith(false)
            .asDriver(onErrorJustReturn: false)

        /*
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
         */

        // Errors
        errorMessages = refreshResults
            .errors()
            .map { error in
                log.debug("\(#function) ERROR : \(error)")
                /// TEMP:
                return "There was an error"
            }
            .asDriver(onErrorJustReturn: "Other Error")
            //.asDriver(onErrorDriveWith: .empty())

        // FetchRequest
        self.filter = NSPredicate(format: "inventory == %@", parentObject)
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = dataManager.createFetchedResultsController(fetchRequest: request)

        // Navigation
        showSelection = bindings.rowTaps
            //.throttle(0.5, scheduler: MainScheduler.instance)
            .map { indexPath in
                return frc.object(at: indexPath)
            }

        self.frc = frc
    }

    // MARK: - AttachableViewModelType

    struct Dependency {
        let dataManager: DataManager
        let parent: Inventory
    }

    struct Bindings {
        let rowTaps: Observable<IndexPath>
        //let uploadTaps: Observable<Void>
    }

}
