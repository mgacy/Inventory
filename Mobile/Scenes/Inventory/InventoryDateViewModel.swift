//
//  InventoryDateViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

//enum InventorySelection {
//    case new(inventory: Inventory)
//    case existing(inventory: Inventory)
//}

struct InventoryDateViewModel {

    // MARK: Properties

    private let dataManager: DataManager

    // CoreData
    private let filter: NSPredicate? = nil
    private let sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
    private let cacheName: String? = nil
    private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input
    let refresh: AnyObserver<Void>
    let addTaps: AnyObserver<Void>
    //let editTaps: AnyObserver<Void>
    let rowTaps: AnyObserver<Inventory>

    // MARK: - Output
    let frc: NSFetchedResultsController<Inventory>
    let isRefreshing: Driver<Bool>
    let hasRefreshed: Driver<Bool>
    //let showInventory: Observable<Inventory>
    //let showLocationCategory: Observable<Inventory>
    //let showSettings: Observable<Void>
    let test: Observable<Inventory>

    // MARK: - Lifecycle

    init(dataManager: DataManager) {
        self.dataManager = dataManager

        // Refresh
        let _refresh = PublishSubject<Void>()
        self.refresh = _refresh.asObserver()

        let isRefreshing = ActivityIndicator()
        self.isRefreshing = isRefreshing.asDriver()

        self.hasRefreshed = _refresh.asObservable()
            .flatMapLatest { _ -> Observable<Bool> in
                log.debug("\(#function) : Refreshing (1) ...")
                return dataManager.refreshStuff()
            }
            .flatMapLatest { _ -> Observable<Bool> in
                log.debug("\(#function) : Refreshing (2) ...")
                return dataManager.refreshInventories()
                    .trackActivity(isRefreshing)
            }
            .asDriver(onErrorJustReturn: false)

        // ...

        // Add
        let _add = PublishSubject<Void>()
        self.addTaps = _add.asObserver()
        _ = _add.asObservable()
            .map { _ in
                log.debug("Tapped ADD")
            }

        // Selection
        let _selectedObjects = PublishSubject<Inventory>()
        self.rowTaps = _selectedObjects.asObserver()
        //self.showDetail = _selectedObjects.asObservable()
        self.test = _selectedObjects.asObservable()
            .map { selection in
                log.debug("Tapped: \(selection)")
                return selection
            }

        // FetchRequest
        let request: NSFetchRequest<Inventory> = Inventory.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false

        let managedObjectContext = dataManager.managedObjectContext
        self.frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext,
                                              sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

}

//extension InventoryDateViewModel: RootSectionViewModel {}
