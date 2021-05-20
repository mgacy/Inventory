//
//  InventoryLocationCategoryViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/11/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

struct InventoryLocCatViewModel {
    //typealias Parent = InventoryLocation
    //typealias Model = InventoryLocationCategory

    // MARK: - Properties

    let frc: NSFetchedResultsController<InventoryLocationCategory>
    var locationName: String { return parentObject.name ?? "Error" }
    let modelSelected: Driver<InventoryLocationCategory>
    private let parentObject: InventoryLocation

    // CoreData
    private let sortDescriptors = [NSSortDescriptor(key: "position", ascending: true),
                                   NSSortDescriptor(key: "name", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Lifecycle

    init(dependency: Dependency, bindings: Bindings, parent: InventoryLocation) {
        self.parentObject = parent

        // FetchRequest
        let request: NSFetchRequest<InventoryLocationCategory> = InventoryLocationCategory.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = NSPredicate(format: "location == %@", parent)
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = dependency.dataManager.makeFetchedResultsController(fetchRequest: request)

        // Selection
        self.modelSelected = bindings.rowTaps
            .map { frc.object(at: $0) }

        self.frc = frc
    }

    // MARK: - AttachableViewModelType

    typealias Dependency = HasDataManager

    struct Bindings {
        let rowTaps: Driver<IndexPath>
    }

}
