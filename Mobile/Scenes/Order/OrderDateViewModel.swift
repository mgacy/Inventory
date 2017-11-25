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
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
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
    let errorMessages: Driver<String>
    let showCollection: Observable<OrderCollection>

    // MARK: - Lifecycle

    // swiftlint:disable:next function_body_length
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
                    .dematerialize()
                    .trackActivity(isRefreshing)
            }
            .asDriver(onErrorJustReturn: false)

        // Add
        let _add = PublishSubject<NewOrderGenerationMethod>()
        self.addTaps = _add.asObserver()
        let showNewResults = _add.asObservable()
            .flatMap { method -> Observable<Event<OrderCollection>> in
                return dataManager.createOrderCollection(generationMethod: method, returnUsage: false,
                                                         periodLength: nil)
            }
            .share()

        // Selection
        let showSelectionResults = rowTaps
            //.throttle(0.5, scheduler: MainScheduler.instance)
            .flatMap { selection -> Observable<Event<OrderCollection>> in
                log.debug("Tapped: \(selection)")
                switch selection.uploaded {
                case true:
                    /// TODO: show PKHUD progress
                    return dataManager.refreshOrderCollection(selection)
                case false:
                    return Observable.just(selection).materialize()
                }
            }
            .share()
            //.shareReplay(1)

        // Navigation
        self.showCollection = Observable.of(showNewResults.elements(), showSelectionResults.elements())
            .merge()

        // Errors
        self.errorMessages = Observable.of(showNewResults.errors(), showSelectionResults.errors())
            .merge()
            .map { error in
                log.debug("\(#function) ERROR : \(error)")
                switch error {
                default:
                    return "There was a problem"
                }
            }
            .asDriver(onErrorJustReturn: "Other Error")
            //.asDriver(onErrorDriveWith: .never())

        // FetchRequest
        let request: NSFetchRequest<OrderCollection> = OrderCollection.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        self.frc = dataManager.createFetchedResultsController(fetchRequest: request)
    }

}
