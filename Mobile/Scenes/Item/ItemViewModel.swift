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

struct ItemViewModel {

    // MARK: Properties

    private let dataManager: DataManager

    // CoreData
    private let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input
    let refresh: AnyObserver<Void>
    // let addTaps: AnyObserver<Void>

    // MARK: - Output
    let frc: NSFetchedResultsController<Item>
    let isRefreshing: Driver<Bool>
    let hasRefreshed: Driver<Bool>
    //let errorMessages: Driver<String>

    // MARK: - Lifecycle

    init(dataManager: DataManager, rowTaps: Observable<IndexPath>) {
        self.dataManager = dataManager

        // Refresh
        let _refresh = PublishSubject<Void>()
        self.refresh = _refresh.asObserver()

        let isRefreshing = ActivityIndicator()
        self.isRefreshing = isRefreshing.asDriver()

        self.hasRefreshed = _refresh.asObservable()
            .flatMapLatest { _ -> Observable<Bool> in
                log.debug("\(#function) : Refreshing (1) ...")
                return dataManager.refreshItems()
                    //.dematerialize()
                    .trackActivity(isRefreshing)
            }
            .asDriver(onErrorJustReturn: false)

        // Errors
        //self.errorMessages = refreshResults.errors().map { error in

        // FetchRequest
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        //request.predicate = filter
        request.sortDescriptors = sortDescriptors
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false

        self.frc = dataManager.createFetchedResultsController(fetchRequest: request)
    }

}
