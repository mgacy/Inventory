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

protocol InvoiceDateViewModelType: RootSectionViewModel {}

struct InvoiceDateViewModel {

    // MARK: Properties

    //private let dataManager: DataManager
    let dataManager: DataManager

    // CoreData
    private let filter: NSPredicate? = nil
    private let sortDescriptors = [NSSortDescriptor(key: "dateTimeInterval", ascending: false)]
    private let cacheName: String? = nil
    private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input
    let refresh: AnyObserver<Void>
    //let addTaps: AnyObserver<Void>
    //let editTaps: AnyObserver<Void>
    //let rowTaps: AnyObserver<InvoiceCollection>

    // MARK: - Output
    let frc: NSFetchedResultsController<InvoiceCollection>
    let isRefreshing: Driver<Bool>
    let hasRefreshed: Driver<Bool>
    let showSelection: Observable<InvoiceCollection>
    //let showSelection: Driver<InvoiceCollection>

    // MARK: - Lifecycle

    init(dataManager: DataManager, rowTaps: Observable<InvoiceCollection>) {
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
                return dataManager.refreshInvoiceCollections()
                    .trackActivity(isRefreshing)
            }
            .asDriver(onErrorJustReturn: false)

        // ...

        // Add
        //let _add = PublishSubject<Void>()
        //self.addTaps = _add.asObserver()
        //_ = _add.asObservable()
        //    .map { _ in
        //        log.debug("Tapped ADD")
        //}

        // Selection
        /*
        let _selectedObjects = PublishSubject<InvoiceCollection>()
        self.rowTaps = _selectedObjects.asObserver()
        self.showSelection = _selectedObjects.asObservable()
            .flatMap { selection -> Observable<InvoiceCollection> in
                log.debug("Tapped: \(selection)")
                return dataManager.refreshInvoiceCollection(selection)
            }
            .shareReplay(1)
            //.asDriver(onErrorJustReturn: InvoiceCollection())
         */
        self.showSelection = rowTaps
            .flatMap { selection -> Observable<InvoiceCollection> in
                log.debug("Tapped: \(selection)")
                return dataManager.refreshInvoiceCollection(selection)
            }
            //.shareReplay(1)

        // FetchRequest
        let request: NSFetchRequest<InvoiceCollection> = InvoiceCollection.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false

        let managedObjectContext = dataManager.managedObjectContext
        self.frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext,
                                              sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

}

//extension InvoiceDateViewModel: RootSectionViewModel {}
//extension InvoiceDateViewModel: InvoiceDateViewModelType {}
