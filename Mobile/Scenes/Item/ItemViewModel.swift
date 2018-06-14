//
//  ItemViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/7/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

struct ItemViewModel: AttachableViewModelType {

    // MARK: Properties
    let frc: NSFetchedResultsController<Item>
    let isRefreshing: Driver<Bool>
    let hasRefreshed: Driver<Bool>
    //let errorMessages: Driver<String>
    // ALT
    //let fetching: Driver<Bool>
    //let errors: Driver<Error>

    //private let dataManager: DataManager

    // CoreData
    private let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Lifecycle

    init(dependency: Dependency, bindings: Bindings) {
        //self.dataManager = dependency.dataManager

        let activityIndicator = ActivityIndicator()
        //let errorTracker = ErrorTracker()

        self.hasRefreshed = bindings.fetchTrigger
            .asObservable()
            .flatMapLatest { _ -> Observable<Bool> in
                //log.debug("\(#function) : Refreshing (1) ...")
                return dependency.dataManager.refreshItems()
                    .catchErrorJustReturn(false)
                    .trackActivity(activityIndicator)
                    //.trackError(errorTracker)
            }
            .asDriver(onErrorJustReturn: false)

        self.isRefreshing = activityIndicator.asDriver()
        //fetching = activityIndicator.asDriver()
        //errors = errorTracker.asDriver()

        // Errors
        //self.errorMessages = refreshResults.errors().map { error in

        // FetchRequest
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        //request.predicate = filter
        request.sortDescriptors = sortDescriptors
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false

        self.frc = dependency.dataManager.createFetchedResultsController(fetchRequest: request)
    }

    // MARK: - AttachableViewModelType

    typealias Dependency = HasDataManager

    struct Bindings {
        let fetchTrigger: Driver<Void>
        //let addTaps: Driver<Void>
        //let editTaps: Driver<Void>
        let rowTaps: Driver<IndexPath>
    }

}
