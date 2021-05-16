//
//  OrderDateViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift
import RxSwiftExt

struct OrderDateViewModel: AttachableViewModelType {

    // MARK: - Properties
    let frc: NSFetchedResultsController<OrderCollection>
    let isRefreshing: Driver<Bool>
    let errorMessages: Driver<String>
    let showCollection: Observable<OrderCollection>

    // CoreData
    private let filter: NSPredicate? = nil
    private let sortDescriptors = [NSSortDescriptor(key: "dateTimeInterval", ascending: false)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Lifecycle

    // swiftlint:disable:next function_body_length
    init(dependency: Dependency, bindings: Bindings) {

        // Refresh
        let activityIndicator = ActivityIndicator()
        self.isRefreshing = activityIndicator.asDriver()
        //let errorTracker = ErrorTracker()
        //self.errors = errorTracker.asDriver()

        let refreshResults = bindings.fetchTrigger
            .asObservable()
            .flatMapLatest { _ -> Observable<Event<Bool>> in
                //log.debug("\(#function) : Refreshing (1) ...")
                return dependency.dataManager.refreshStuff()
                    .materialize()
            }
            .flatMapLatest { _ -> Observable<Event<Bool>> in
                //log.debug("\(#function) : Refreshing (2) ...")
                return dependency.dataManager.refreshOrderCollections()
                    .trackActivity(activityIndicator)
            }
            .share()

        // Add
        let showNewResults = bindings.addTaps.asObservable()
            .flatMap { method -> Observable<Event<OrderCollection>> in
                return dependency.dataManager.createOrderCollection(generationMethod: method, returnUsage: false,
                                                         periodLength: nil)
            }
            .share()

        // FetchRequest
        let request: NSFetchRequest<OrderCollection> = OrderCollection.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = dependency.dataManager.makeFetchedResultsController(fetchRequest: request)

        // Selection
        let showSelectionResults = bindings.rowTaps
            //.throttle(0.5, scheduler: MainScheduler.instance)
            .asObservable()
            .map { frc.object(at: $0) }
            .flatMap { selection -> Observable<Event<OrderCollection>> in
                switch selection.uploaded {
                case true:
                    /// FIXME: simply push view; refresh on next scene
                    // TODO: show PKHUD progress
                    return dependency.dataManager.refreshOrderCollection(selection)
                case false:
                    return Observable.just(selection).materialize()
                }
            }
            .share()

        // Navigation
        self.showCollection = Observable.of(showNewResults.elements(), showSelectionResults.elements())
            .merge()

        // Errors
        self.errorMessages = Observable.of(
                showNewResults.errors(), showSelectionResults.errors(), refreshResults.errors()
            )
            .merge()
            .map { error in
                log.debug("\(#function) ERROR : \(error)")
                return error.localizedDescription
            }
            .asDriver(onErrorJustReturn: "Unrecognized Error")

        self.frc = frc
    }

    // MARK: - AttachableViewModelType

    typealias Dependency = HasDataManager

    struct Bindings {
        let fetchTrigger: Driver<Void>
        let addTaps: Driver<NewOrderGenerationMethod>
        //let editTaps: Driver<Void>
        let rowTaps: Driver<IndexPath>
    }

    enum GenerationMethod: CustomStringConvertible {
        //case count(method: NewOrderGenerationMethod)
        //case par(method: NewOrderGenerationMethod)
        case count
        case par
        //case sales
        case cancel

        var description: String {
            switch self {
            case .count:
                return "From Count"
            case .par:
                return "From Par"
            case .cancel:
                return "Cancel"
            }
        }
    }

}
