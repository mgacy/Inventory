//
//  OrderLocCatViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

final class OrderLocCatViewModel: AttachableViewModelType {

    // MARK: - Properties
    let frc: NSFetchedResultsController<OrderLocationCategory>
    let selectedCategory: Observable<OrderLocationCategory>

    // CoreData
    private let filter: NSPredicate? = nil
    private let sortDescriptors = [NSSortDescriptor(key: "position", ascending: false)]
    //private let sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Lifecycle

    init(dependency: Dependency, bindings: Bindings) {

        // FetchRequest
        let request: NSFetchRequest<OrderLocationCategory> = OrderLocationCategory.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = NSPredicate(format: "location == %@", dependency.location)
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = dependency.dataManager.makeFetchedResultsController(fetchRequest: request)

        // Navigation
        self.selectedCategory = bindings.rowTaps
            .debug("Selection (1)")
            .asObservable()
            .map { frc.object(at: $0) }
            .debug("Selection (2)")
            .share(replay: 1)

        self.frc = frc
    }

    // MARK: - AttachableViewModelType

    struct Dependency {
        let dataManager: DataManager
        let location: OrderLocation
    }

    struct Bindings {
        let rowTaps: Observable<IndexPath>
    }

}
