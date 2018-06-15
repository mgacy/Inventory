//
//  InvoiceDateViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift
import RxSwiftExt

struct InvoiceDateViewModel: AttachableViewModelType {

    // MARK: Properties
    let frc: NSFetchedResultsController<InvoiceCollection>
    let isRefreshing: Driver<Bool>
    let hasRefreshed: Driver<Bool>
    let errorMessages: Driver<String>
    let showCollection: Observable<InvoiceCollection>
    //private let dataManager: DataManager

    // CoreData
    private let filter: NSPredicate? = nil
    private let sortDescriptors = [NSSortDescriptor(key: "dateTimeInterval", ascending: false)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Lifecycle

    init(dependency: Dependency, bindings: Bindings) {
        //self.dataManager = dependency.dataManager

        // Refresh
        let isRefreshing = ActivityIndicator()
        self.isRefreshing = isRefreshing.asDriver()
        /// TODO: add error tracker

        self.hasRefreshed = bindings.fetchTrigger
            .asObservable()
            .flatMapLatest { _ -> Observable<Bool> in
                log.debug("\(#function) : Refreshing (1) ...")
                return dependency.dataManager.refreshStuff()
                    .catchErrorJustReturn(false)
            }
            .flatMapLatest { _ -> Observable<Bool> in
                log.debug("\(#function) : Refreshing (2) ...")
                return dependency.dataManager.refreshInvoiceCollections()
                    .dematerialize()
                    .catchErrorJustReturn(false)
                    .trackActivity(isRefreshing)
            }
            .asDriver(onErrorJustReturn: false)

        // FetchRequest
        let request: NSFetchRequest<InvoiceCollection> = InvoiceCollection.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = dependency.dataManager.createFetchedResultsController(fetchRequest: request)

        // Selection
        let showSelectionResults = bindings.rowTaps
            .asObservable()
            .map { frc.object(at: $0) }
            .flatMap { selection -> Observable<Event<InvoiceCollection>> in
                //log.debug("Tapped: \(selection)")
                return dependency.dataManager.refreshInvoiceCollection(selection)
            }
            .share(replay: 1)
            //.shareReplay(1)

        // Errors
        self.errorMessages = showSelectionResults
            .errors()
            .map { error in
                log.debug("\(#function) ERROR : \(error)")
                /// TEMP:
                return "There was an error"
            }
            .asDriver(onErrorJustReturn: "Other Error")
            //.asDriver(onErrorDriveWith: .empty())

        // Navigation
        self.showCollection = showSelectionResults.elements()

        self.frc = frc
    }

    // MARK: - AttachableViewModelType

    typealias Dependency = HasDataManager

    struct Bindings {
        let fetchTrigger: Driver<Void>
        let rowTaps: Driver<IndexPath>
    }

}
