//
//  OrderLocationViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift
import RxSwiftExt

final class OrderLocationViewModel: AttachableViewModelType {

    // MARK: - Properties
    let frc: NSFetchedResultsController<OrderLocation>
    let isRefreshing: Driver<Bool>
    let showTable: Driver<Bool>
    let errorMessages: Driver<String>
    let selectedLocation: Observable<OrderLocation>

    // CoreData
    private let filter: NSPredicate? = nil
    private let sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Lifecycle

    init(dependency: Dependency, bindings: Bindings) {

        // Activity
        let isRefreshing = ActivityIndicator()
        self.isRefreshing = isRefreshing.asDriver()

        // Fetch Locations
        let locationResults = bindings.fetchTrigger
            .asObservable()
            .startWith(())
            .flatMapLatest { _ -> Observable<Event<[RemoteLocation]>> in
                return dependency.dataManager.getLocations()
                .trackActivity(isRefreshing)
            }
            .share()

        self.showTable = locationResults
            .elements()
            .map { locations -> [OrderLocation] in
                return dependency.collection.syncOrderLocations(with: locations,
                                                                in: dependency.dataManager.managedObjectContext)
            }
            .map { locations -> Bool in
                return locations.count > 0
            }
            .startWith(false)
            .asDriver(onErrorJustReturn: false)

        // FetchRequest
        let request: NSFetchRequest<OrderLocation> = OrderLocation.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        //request.predicate = NSPredicate(format: "\(Self.remoteIdentifierName) == \(identifier)")
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = dependency.dataManager.makeFetchedResultsController(fetchRequest: request)

        // Errors
        self.errorMessages = locationResults.errors()
            .map { error in
                log.debug("\(#function) ERROR : \(error)")
                return error.localizedDescription
            }
            .asDriver(onErrorJustReturn: "Unrecognized Error")

        // Navigation
        self.selectedLocation = bindings.rowTaps
            .asObservable()
            .map { frc.object(at: $0) }
            //.debug("Selection")
            .share(replay: 1)

        self.frc = frc
    }

    // MARK: - AttachableViewModelType

    struct Dependency {
        let dataManager: DataManager
        let collection: OrderCollection
    }

    struct Bindings {
        let fetchTrigger: Driver<Void>
        let rowTaps: Observable<IndexPath>
    }

}
