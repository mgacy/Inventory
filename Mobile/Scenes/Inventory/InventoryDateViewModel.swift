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
    //let rowTaps: AnyObserver<Inventory>

    // MARK: - Output
    let frc: NSFetchedResultsController<Inventory>
    let isRefreshing: Driver<Bool>
    let hasRefreshed: Driver<Bool>
    let errorMessages: Driver<String>
    let showInventory: Observable<Inventory>
    //let showLocationCategory: Observable<Inventory>

    // MARK: - Lifecycle

    // swiftlint:disable:next function_body_length
    init(dataManager: DataManager, rowTaps: Observable<Inventory>) {
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
                    .dematerialize()
                    .trackActivity(isRefreshing)
            }
            .asDriver(onErrorJustReturn: false)

        // Add
        let _add = PublishSubject<Void>()
        self.addTaps = _add.asObserver()
        let showNewResults = _add.asObservable()
            .flatMap { _ -> Observable<Event<Inventory>> in
                log.debug("Tapped ADD")
                return dataManager.createInventory()
            }
            .share()

        // Selection
        //let _selectedObjects = PublishSubject<Inventory>()
        //self.rowTaps = _selectedObjects.asObserver()
        //let showSelectionResults = _selectedObjects.asObservable()
        let showSelectionResults = rowTaps
            .flatMap { selection -> Observable<Event<Inventory>> in
                log.debug("Tapped: \(selection)")
                //return Observable.just(selection).materialize()
                switch selection.uploaded {
                case true:
                    return dataManager.refreshInventory(selection)
                case false:
                    return Observable.just(selection).materialize()
                }
            }
            .share()

        // Navigation
        self.showInventory = Observable.of(showNewResults.elements(), showSelectionResults.elements())
            .merge()

        // Errors
        self.errorMessages = Observable.of(showNewResults.errors(), showSelectionResults.errors())
            .merge()
            .map { error in
                log.debug("\(#function) ERROR : \(error)")
                return "There was an error"
            }
            .asDriver(onErrorJustReturn: "Other Error")
            //.asDriver(onErrorDriveWith: .never())

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
