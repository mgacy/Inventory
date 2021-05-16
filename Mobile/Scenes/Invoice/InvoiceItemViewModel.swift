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

struct InvoiceItemViewModel: AttachableViewModelType {

    // MARK: - Properties
    let frc: NSFetchedResultsController<InvoiceItem>
    let vendorName: String
    let isUploading: Driver<Bool>
    let uploadResults: Observable<Event<Invoice>>
    // TODO: add uploadIsEnabled: Driver<Bool>
    let itemSelected: Observable<IndexPath>

    private let dataManager: DataManager
    private let parentObject: Invoice

    // CoreData
    private let filter: NSPredicate? = nil
    private let sortDescriptors = [NSSortDescriptor(key: "item.name", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Lifecycle

    init(dependency: Dependency, bindings: Bindings) {
        self.dataManager = dependency.dataManager
        self.parentObject = dependency.parentObject

        // TODO: use computed property instead?
        self.vendorName = dependency.parentObject.vendor?.name ?? "Error"

        // Upload
        let isUploading = ActivityIndicator()
        self.isUploading = isUploading.asDriver()

        self.uploadResults = bindings.uploadTaps
            .flatMap { _ -> Observable<Event<Invoice>> in
                log.debug("Starting to upload")
                return dependency.dataManager.updateInvoice(dependency.parentObject)
                    .trackActivity(isUploading)
            }
            .share()

        // Navigation
        self.itemSelected = bindings.rowTaps

        // FetchRequest
        let predicate = NSPredicate(format: "invoice == %@", dependency.parentObject)
        let request: NSFetchRequest<InvoiceItem> = InvoiceItem.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        self.frc = dataManager.makeFetchedResultsController(fetchRequest: request)
    }

    // MARK: Model

    func updateItemStatus(forItemAt indexPath: IndexPath, withStatus status: InvoiceItemStatus) {
        // TODO: add `completion: () -> Void` arg to so view controller can do `self?.isEditing = false` as completion?
        let invoiceItem = frc.object(at: indexPath)
        invoiceItem.status = status.rawValue
        parentObject.updateStatus() // ???
        // TODO: dataManager.updateInvoiceItem?
        dataManager.saveOrRollback()
        log.info("Updated InvoiceItem: \(invoiceItem)")
    }

    // MARK: - AttachableViewModelType

    struct Dependency {
        let dataManager: DataManager
        let parentObject: Invoice
    }

    struct Bindings {
        let rowTaps: Observable<IndexPath>
        let uploadTaps: Observable<Void>
    }

}
