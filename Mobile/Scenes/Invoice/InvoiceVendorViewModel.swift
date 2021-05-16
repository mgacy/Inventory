//
//  InvoiceVendorViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/11/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

/// TODO: make class?
struct InvoiceVendorViewModel: AttachableViewModelType {

    // MARK: - Properties
    let frc: NSFetchedResultsController<Invoice>
    let fetching: Driver<Bool>
    let showTable: Driver<Bool>
    //let errors: Driver<Error>
    let errorMessages: Driver<String>
    let selectedItem: Driver<Invoice>

    // CoreData
    private let filter: NSPredicate?
    private let sortDescriptors = [NSSortDescriptor(key: "vendor.name", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    init(dependency: Dependency, bindings: Bindings) {

        let activityIndicator = ActivityIndicator()
        //let errorTracker = ErrorTracker()

        let refreshResults = dependency.dataManager.refreshInvoiceCollection(dependency.parentObject)
            .trackActivity(activityIndicator)
            //.trackError(errorTracker)
            .share()

        self.showTable = refreshResults
            .elements()
            .map { collection -> Bool in
                log.debug("\(#function) : \(collection)")
                if let itemCount = collection.invoices?.count {
                    return itemCount > 0
                }
                return false
            }
            .startWith(false)
            .asDriver(onErrorJustReturn: false)

        fetching = activityIndicator.asDriver()
        //errors = errorTracker.asDriver()
        errorMessages = refreshResults.errors()
            .map { $0.localizedDescription }
            .asDriver(onErrorJustReturn: "Unrecognized Error")

        // FetchRequest
        filter = NSPredicate(format: "collection == %@", dependency.parentObject)
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = dependency.dataManager.makeFetchedResultsController(fetchRequest: request)

        // Navigation
        self.selectedItem = bindings.rowTaps
            .map { frc.object(at: $0) }

        self.frc = frc
    }

    // MARK: - AttachableViewModelType

    struct Dependency {
        let dataManager: DataManager
        let parentObject: InvoiceCollection
    }

    struct Bindings {
        let rowTaps: Driver<IndexPath>
    }

}
