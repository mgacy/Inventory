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
import RxSwiftExt

enum InventorySelection {
    case new(Inventory)
    case existing(Inventory)
}

struct InventoryDateViewModel: AttachableViewModelType {

    // MARK: Properties
    let frc: NSFetchedResultsController<Inventory>
    let isRefreshing: Driver<Bool>
    //let hasRefreshed: Driver<Bool>
    let errorMessages: Driver<String>
    //let errors: Driver<Error>
    let showInventory: Observable<InventorySelection>
    //private let dataManager: DataManager

    // CoreData
    private let sortDescriptors = [NSSortDescriptor(key: "dateTimeInterval", ascending: false)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Lifecycle

    init(dependency: Dependency, bindings: Bindings) {
        //self.dataManager = dependency.dataManager

        let activityIndicator = ActivityIndicator()
        //let errorTracker = ErrorTracker()

        // Refresh
        let refreshResults = bindings.fetchTrigger
            .asObservable()
            .flatMapLatest { _ -> Observable<Event<Bool>> in
                //log.debug("\(#function) : Refreshing (1) ...")
                return dependency.dataManager.refreshStuff()
                    .materialize()
            }
            .flatMapLatest { _ -> Observable<Event<Bool>> in
                //log.debug("\(#function) : Refreshing (2) ...")
                return dependency.dataManager.refreshInventories()
                    .trackActivity(activityIndicator)
            }
            .share()
        /*
        self.hasRefreshed = refreshResults
            .elements()
            .asDriver(onErrorJustReturn: false)
        */
        self.isRefreshing = activityIndicator.asDriver()
        //self.errors = errorTracker.asDriver()

        // Add
        /// TODO: go ahead and push new view controller and have that be responsible for POST?
        let showNewResults = bindings.addTaps
            .asObservable()
            .flatMap { _ -> Observable<Event<Inventory>> in
                return dependency.dataManager.createInventory()
            }
            /// TODO: .map { InventorySelection.new($0) }
            .share()

        // FetchRequest
        let request: NSFetchRequest<Inventory> = Inventory.fetchRequest()
        //request.predicate = filter
        request.sortDescriptors = sortDescriptors
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = dependency.dataManager.createFetchedResultsController(fetchRequest: request)

        // Selection
        let showSelection = bindings.rowTaps
            /// TODO: .map { InventorySelection.existing($0) }
            .map { frc.object(at: $0) }
            .share()

        // Navigation
        self.showInventory = Observable.of(showNewResults.elements(), showSelection)
            .merge()
            .map { inventory in
                switch inventory.uploaded {
                case true:
                    return InventorySelection.existing(inventory)
                case false:
                    return InventorySelection.new(inventory)
                }
            }

        // Errors
        self.errorMessages = Observable.of(showNewResults.errors(), refreshResults.errors())
            .merge()
            .map { error in
                log.debug("\(#function) ERROR : \(error)")
                return error.localizedDescription
            }
            .asDriver(onErrorJustReturn: "Unrecognized Error")

        self.frc = frc
    }

    // MARK: - AttachableViewModelType

    typealias Dependency = HasDataManager

    struct Bindings {
        let fetchTrigger: Driver<Void>
        let addTaps: Driver<Void>
        //let editTaps: Observable<Void>
        let rowTaps: Observable<IndexPath>
    }

}
