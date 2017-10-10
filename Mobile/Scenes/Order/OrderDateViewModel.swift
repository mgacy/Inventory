//
//  OrderDateViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

struct OrderDateViewModel {

    // MARK: - Properties

    private let dataManager: DataManager

    // CoreData
    private let filter: NSPredicate? = nil
    private let sortDescriptors = [NSSortDescriptor(key: "dateTimeInterval", ascending: false)]
    private let cacheName: String? = nil
    private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input
    let refresh: AnyObserver<Void>
    let addTaps: AnyObserver<NewOrderGenerationMethod>
    //let editTaps: AnyObserver<Void>
    //let rowTaps: AnyObserver<InvoiceCollection>

    // MARK: - Output
    let frc: NSFetchedResultsController<OrderCollection>
    let isRefreshing: Driver<Bool>
    let hasRefreshed: Driver<Bool>
    //let errorMessages: Driver<String>
    let showCollection: Observable<OrderCollection>

    // MARK: - Lifecycle

    //swiftlint:disable:next function_body_length
    init(dataManager: DataManager, rowTaps: Observable<OrderCollection>) {
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
                return dataManager.refreshOrderCollections()
                    .trackActivity(isRefreshing)
            }
            .asDriver(onErrorJustReturn: false)

        // Add
        let _add = PublishSubject<NewOrderGenerationMethod>()
        self.addTaps = _add.asObserver()

        let showNew = _add.asObservable()
            .flatMap { method -> Observable<OrderCollection> in
                return dataManager.createOrderCollection(generationMethod: method, returnUsage: false,
                                                         periodLength: nil).dematerialize()
            }

        // Selection
        let showSelection = rowTaps
            //.throttle(0.5, scheduler: MainScheduler.instance)
            .flatMap { selection -> Observable<OrderCollection> in
                log.debug("Tapped: \(selection)")
                return dataManager.refreshOrderCollection(selection)

            }
            .shareReplay(1)

        // Navigation
        //self.showCollection = Observable.from([showNew, showSelection]).merge()
        self.showCollection = Observable.of(showNew, showSelection)
            .merge()

        // FetchRequest
        let request: NSFetchRequest<OrderCollection> = OrderCollection.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false

        let managedObjectContext = dataManager.managedObjectContext
        self.frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext,
                                              sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

}

