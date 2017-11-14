//
//  InventoryLocationViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/11/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

enum InventoryLocationSegue {
    //case back
    case item(InventoryLocation)
    case category(InventoryLocation)
}

struct InventoryLocationViewModel {

    // MARK: Properties

    let dataManager: DataManager
    private let parentObject: Inventory

    // CoreData
    private let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input
    //let uploadTaps: AnyObserver<Void>
    //let rowTaps: AnyObserver<InventoryLocation>

    // MARK: - Output
    let frc: NSFetchedResultsController<InventoryLocation>
    let isUploading: Driver<Bool>
    let uploadResults: Observable<Event<Inventory>>
    //let showTable: Driver<Bool>
    let showLocation: Observable<InventoryLocationSegue>

    // MARK: - Lifecycle

    init(dataManager: DataManager, parentObject: Inventory, rowTaps: Observable<IndexPath>, uploadTaps: Observable<Void>) {
        self.dataManager = dataManager
        self.parentObject = parentObject

        // Upload
        let isUploading = ActivityIndicator()
        self.isUploading = isUploading.asDriver()

        self.uploadResults = uploadTaps
            .flatMap { _ -> Observable<Event<Inventory>> in
                log.debug("Starting to upload")
                return dataManager.updateInventory(parentObject)
                    .trackActivity(isUploading)
            }
            .share()

        // FetchRequest
        let request: NSFetchRequest<InventoryLocation> = InventoryLocation.fetchRequest()
        request.predicate = NSPredicate(format: "inventory == %@", parentObject)
        request.sortDescriptors = sortDescriptors
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = dataManager.createFetchedResultsController(fetchRequest: request)
        self.frc = frc

        // Navigation
        self.showLocation = rowTaps
            .map { frc.object(at: $0) }
            .map { selection in
                log.debug("Selected: \(selection)")
                switch selection.locationType {
                case "category"?:
                    return InventoryLocationSegue.category(selection)
                case "item"?:
                    return InventoryLocationSegue.item(selection)
                default:
                    fatalError("\(#function) FAILED : wrong locationType")
                }
            }
            //.asDriver()
            //.share()
    }

}
