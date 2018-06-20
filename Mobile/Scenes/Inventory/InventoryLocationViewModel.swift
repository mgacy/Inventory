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
import RxSwiftExt

enum InventoryLocationSegue {
    case item(InventoryLocation)
    case category(InventoryLocation)
}

final class InventoryLocationViewModel: AttachableViewModelType {

    struct Dependency {
        let dataManager: DataManager
        let parentObject: Inventory
    }

    struct Bindings {
        let cancelTaps: Observable<Void>
        let rowTaps: Observable<IndexPath>
        let uploadTaps: Observable<Void>
    }

    // MARK: Dependencies
    //private let dataManager: DataManager
    //private let parentObject: Inventory

    // MARK: Properties
    let frc: NSFetchedResultsController<InventoryLocation>
    let isUploading: Driver<Bool>
    let uploadResults: Observable<Event<Inventory>>
    let showLocation: Observable<InventoryLocationSegue>
    let dismissView: Observable<Void>

    // CoreData
    private let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Lifecycle

    init(dependency: Dependency, bindings: Bindings) {
        //self.dataManager = dataManager
        //self.parentObject = parentObject

        // Upload
        let isUploading = ActivityIndicator()
        self.isUploading = isUploading.asDriver()

        self.uploadResults = bindings.uploadTaps
            .flatMap { _ -> Observable<Event<Inventory>> in
                log.debug("Starting to upload")
                return dependency.dataManager.updateInventory(dependency.parentObject)
                    .trackActivity(isUploading)
            }
            .share()

        let uploadSuccess = self.uploadResults
            .elements()
            .map { _ in return }

        // FetchRequest
        let request: NSFetchRequest<InventoryLocation> = InventoryLocation.fetchRequest()
        request.predicate = NSPredicate(format: "inventory == %@", dependency.parentObject)
        request.sortDescriptors = sortDescriptors
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = dependency.dataManager.makeFetchedResultsController(fetchRequest: request)
        self.frc = frc

        // Navigation
        self.showLocation = bindings.rowTaps
            .map { frc.object(at: $0) }
            .map { selection in
                //log.debug("Selected: \(selection)")
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

        self.dismissView = Observable.merge(bindings.cancelTaps, uploadSuccess)
            .take(1)
    }

}
