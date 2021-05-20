//
//  OrderLocItemViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/26/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

enum OrderLocItemParent {
    case location(OrderLocation)
    case category(OrderLocationCategory)
    //case remoteLocation(RemoteLocation)
    //case remoteCategory(RemoteItemCategory)

    var fetchPredicate: NSPredicate? {
        switch self {
        case .category(let category):
            return NSPredicate(format: "category == %@", category)
        case .location(let location):
            return NSPredicate(format: "location == %@", location)
        }
    }

}

struct OrderLocItemViewModel: AttachableViewModelType {

    // MARK: - Properties
    let frc: NSFetchedResultsController<OrderLocationItem>
    let navTitle: String
    //let itemSelected: Observable<IndexPath>

    // CoreData
    /// NOTE: for InventoryLocItemViewModel we use both position and item.name
    private let sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Lifecycle

    init(dependency: Dependency, bindings: Bindings) {
        switch dependency.parent {
        case .category(let category):
            self.navTitle = category.name ?? "Error"
        case .location(let location):
            self.navTitle = location.name ?? "Error"
        }

        // FetchRequest
        let request: NSFetchRequest<OrderLocationItem> = OrderLocationItem.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = dependency.parent.fetchPredicate
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        self.frc = dependency.dataManager.makeFetchedResultsController(fetchRequest: request)

        //self.itemSelected = bindings.rowTaps
    }

    // MARK: - AttachableViewModelType

    struct Dependency {
        let dataManager: DataManager
        let parent: OrderLocItemParent
    }

    struct Bindings {
        let rowTaps: Observable<IndexPath>
    }

}
