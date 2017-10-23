//
//  InvoiceItemViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/22/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

struct InvoiceItemViewModel {

    // MARK: - Properties

    let dataManager: DataManager
    private var parentObject: Invoice

    // CoreData
    private let filter: NSPredicate? = nil
    private let sortDescriptors = [NSSortDescriptor(key: "item.name", ascending: true)]
    private let cacheName: String? = nil
    private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input
    // let uploadTaps:

    // MARK: - Output
    let frc: NSFetchedResultsController<InvoiceItem>
    let isUploading: Driver<Bool>
    let uploadResults: Observable<Event<Invoice>>

    // MARK: - Lifecycle

    init(dataManager: DataManager, parentObject: Invoice, rowTaps: Observable<InvoiceItem>, uploadTaps: Observable<Void>) {
        self.dataManager = dataManager
        self.parentObject = parentObject

        // Upload
        let isUploading = ActivityIndicator()
        self.isUploading = isUploading.asDriver()

        self.uploadResults = uploadTaps
            .flatMap { _ -> Observable<Event<Invoice>> in
                log.debug("Starting to upload")
                return dataManager.updateInvoice(parentObject)
                    .trackActivity(isUploading)
            }
            .share()

        // Navigation

        // FetchRequest
        let predicate = NSPredicate(format: "invoice == %@", parentObject)
        let request: NSFetchRequest<InvoiceItem> = InvoiceItem.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false

        let managedObjectContext = dataManager.managedObjectContext
        self.frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext,
                                              sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

}
