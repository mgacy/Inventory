//
//  InventoryLocItemViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/23/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

enum LocationItemListParent {
    case category(InventoryLocationCategory)
    case location(InventoryLocation)

    var fetchPredicate: NSPredicate? {
        switch self {
        case .category(let category):
            return NSPredicate(format: "category == %@", category)
        case .location(let location):
            return NSPredicate(format: "location == %@", location)
        }
    }

}

struct InventoryLocItemViewModel {
    //typealias Parent = LocationItemListParent
    //typealias Model = InventoryLocationItem

    // MARK: - Properties
    let frc: NSFetchedResultsController<InventoryLocationItem>
    let windowTitle: String

    // CoreData
    private let sortDescriptors = [NSSortDescriptor(key: "position", ascending: true),
                                   NSSortDescriptor(key: "item.name", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Lifecycle

    init(dependency: Dependency, parent: LocationItemListParent) {
        // Title
        switch parent {
        case .category(let parentCategory):
            self.windowTitle = parentCategory.name ?? "Error"
        case .location(let parentLocation):
            self.windowTitle = parentLocation.name ?? "Error"
        }

        // FetchRequest
        let request: NSFetchRequest<InventoryLocationItem> = InventoryLocationItem.fetchRequest()
        request.predicate = parent.fetchPredicate
        request.sortDescriptors = sortDescriptors
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        self.frc = dependency.dataManager.makeFetchedResultsController(fetchRequest: request)
    }

    // MARK: - AttachableViewModelType

    typealias Dependency = HasDataManager

    //struct Bindings {
    //    let rowTaps: Driver<IndexPath>
    //}

}
