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

struct InvoiceVendorViewModel {

    // MARK: - Properties

    //private let dataManager: DataManager
    let dataManager: DataManager
    private let parentObject: InvoiceCollection

    // CoreData
    private let filter: NSPredicate?
    private let sortDescriptors = [NSSortDescriptor(key: "vendor.name", ascending: true)]
    private let cacheName: String? = nil
    private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input

    // MARK: - Output
    let frc: NSFetchedResultsController<Invoice>
    //let isRefreshing: Driver<Bool>
    //let hasRefreshed: Driver<Bool>
    //let showSelection: Observable<Invoice>
    //let errorMessages: Driver<String>

    init(dataManager: DataManager, parentObject: InvoiceCollection) {
        self.dataManager = dataManager
        self.parentObject = parentObject

        // Activity

        // Selection

        // Navigation
        //showSelection =

        // Errors
        //errorMessages =

        // FetchRequest
        filter = NSPredicate(format: "collection == %@", parentObject)
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false

        let managedObjectContext = dataManager.managedObjectContext
        self.frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext,
                                              sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

}
