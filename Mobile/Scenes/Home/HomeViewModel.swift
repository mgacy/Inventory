//
//  HomeViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/7/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCoreData
import RxCocoa
import RxSwift
import RxSwiftExt

final class HomeViewModel: AttachableViewModelType {

    typealias Dependency = HasDataManager

    struct Bindings {
        let addInventoryTaps: Observable<Void>
        let addOrderTaps: Observable<NewOrderGenerationMethod>
        let selection: Driver<IndexPath>
    }

    enum PendingTransition {
        // TODO: name cases `showInventory`, etc?
        // TODO: add fetchPredicate or frc as associated value?
        case inventory
        case order
        case invoice
    }

    // MARK: Dependencies
    //let dataManager: DataManager

    // MARK: Properties
    let storeName: Driver<String>
    let isLoading: Driver<Bool>
    let errorMessages: Driver<String>
    let showInventory: Observable<Inventory>
    let showOrder: Observable<OrderCollection>
    // MARK: TableView
    let pendingInventoryCount: Driver<String>
    let pendingOrderCount: Driver<String>
    let pendingInvoiceCount: Driver<String>
    let transition: Driver<PendingTransition>

    // MARK: - Lifecycle

    // swiftlint:disable:next function_body_length
    required init(dependency: Dependency, bindings: Bindings) {
        //self.dataManager = model.dataManager

        // FIXME: actually get this from somewhere
        self.storeName = Observable.just("Lux").asDriver(onErrorJustReturn: "")

        // Loading
        let isLoading = ActivityIndicator()

        // Inventory
        let createInventoryResults = bindings.addInventoryTaps
            .throttle(0.5, scheduler: MainScheduler.instance)
            .flatMap { _ -> Observable<Event<Inventory>> in
                return dependency.dataManager.createInventory()
                    .trackActivity(isLoading)
            }
            .share()
        //self.showInventory = createInventoryResults.elements().asDriver(onErrorDriveWith: .empty())
        self.showInventory = createInventoryResults.elements()

        // Order
        let createOrderResults = bindings.addOrderTaps
            .throttle(0.5, scheduler: MainScheduler.instance)
            .flatMap { method -> Observable<Event<OrderCollection>> in
                return dependency.dataManager.createOrderCollection(generationMethod: method, returnUsage: false)
                    .trackActivity(isLoading)
            }
            .share()
        self.showOrder = createOrderResults.elements()

        self.isLoading = isLoading.asDriver()

        // Errors
        self.errorMessages = Observable.of(createInventoryResults.errors(), createOrderResults.errors())
            .merge()
            .map { error in
                log.debug("\(#function) ERROR : \(error)")
                return error.localizedDescription
            }
            .asDriver(onErrorJustReturn: "Unrecognized Error")

        // MARK: TableView
        // TODO: check local or remote for pending?

        guard let currentStoreID = dependency.dataManager.userManager.storeID else {
            fatalError("\(#function) FAILED : no storeID")
        }
        let predicate1 = NSPredicate(format: "storeID == \(currentStoreID)")
        let predicate2 = NSPredicate(format: "uploaded == %@", NSNumber(value: false))
        let fetchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
        let sortDescriptors = [NSSortDescriptor(key: "dateTimeInterval", ascending: false)]

        // Inventory
        let pendingInventoryRequest: NSFetchRequest<Inventory> = Inventory.fetchRequest()
        pendingInventoryRequest.predicate = fetchPredicate
        pendingInventoryRequest.sortDescriptors = sortDescriptors
        pendingInventoryCount = dependency.dataManager.viewContext.rx.entities(fetchRequest: pendingInventoryRequest)
            .map { "\($0.count)" }
            .asDriver(onErrorJustReturn: "Error")

        // Order
        let pendingOrderRequest: NSFetchRequest<OrderCollection> = OrderCollection.fetchRequest()
        pendingOrderRequest.predicate = fetchPredicate
        pendingOrderRequest.sortDescriptors = sortDescriptors
        pendingOrderCount = dependency.dataManager.viewContext.rx.entities(fetchRequest: pendingOrderRequest)
            .map { "\($0.count)" }
            .asDriver(onErrorJustReturn: "Error")

        // Invoice
        let pendingInvoiceRequest: NSFetchRequest<InvoiceCollection> = InvoiceCollection.fetchRequest()
        pendingInvoiceRequest.predicate = fetchPredicate
        pendingInvoiceRequest.sortDescriptors = sortDescriptors
        pendingInvoiceCount = dependency.dataManager.viewContext.rx.entities(fetchRequest: pendingInvoiceRequest)
            .map { "\($0.count)" }
            .asDriver(onErrorJustReturn: "Error")

        self.transition = bindings.selection
            .map { indexPath -> PendingTransition in
                switch indexPath.row {
                case 0:
                    return .inventory
                case 1:
                    return .order
                case 2:
                    return .invoice
                default:
                    fatalError("Unknown row in section 0")
                }
            }
    }

}
