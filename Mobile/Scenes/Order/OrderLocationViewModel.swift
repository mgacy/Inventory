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

struct OrderLocationViewModel {

    // MARK: - Properties

    private let dataManager: DataManager
    private let collection: OrderCollection
    private let factory: OrderLocationFactory

    // MARK: - Input

    // MARK: - Output
    let isRefreshing: Driver<Bool>
    let showTable: Driver<Bool>
    let locations: Observable<[RemoteLocation]>
    let errorMessages: Driver<String>
    //let selectedLocation: Observable<RemoteLocation>

    // MARK: - Lifecycle

    init(dependency: Dependency) {
        self.dataManager = dependency.dataManager
        self.collection = dependency.collection
        self.factory = OrderLocationFactory(collection: collection, in: dataManager.managedObjectContext)

        // Activity
        let isRefreshing = ActivityIndicator()
        self.isRefreshing = isRefreshing.asDriver()

        // Fetch Locations
        let locationResults = dataManager.getLocations()
            .trackActivity(isRefreshing)
            .share()

        self.showTable = locationResults
            .elements()
            .map { locations -> Bool in
                return locations.count > 0
            }
            .startWith(false)
            .asDriver(onErrorJustReturn: false)

        // Errors
        self.errorMessages = locationResults.errors()
            .map { error in
                log.debug("\(#function) ERROR : \(error)")
                return error.localizedDescription
            }
            .asDriver(onErrorJustReturn: "Unrecognized Error")

        self.locations = locationResults.elements()
    }

    // MARK: -

    struct Dependency {
        let dataManager: DataManager
        let collection: OrderCollection
    }

    //struct Bindings {
    //    let rowTaps: Observable<IndexPath>
    //}

}
