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
    let selectedItem: Driver<Invoice>

    // CoreData
    private let filter: NSPredicate?
    private let sortDescriptors = [NSSortDescriptor(key: "vendor.name", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    init(dependency: Dependency, bindings: Bindings) {

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
