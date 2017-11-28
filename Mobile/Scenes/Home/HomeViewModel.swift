//
//  HomeViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/7/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxSwiftExt

final class HomeViewModel: AttachableViewModelType {

    struct Dependency {
        let dataManager: DataManager
    }

    struct Bindings {
        let addInventoryTaps: Observable<Void>
        let addOrderTaps: Observable<NewOrderGenerationMethod>
    }

    // MARK: Dependencies
    //let dataManager: DataManager

    // MARK: Properties
    let storeName: Driver<String>
    let isLoading: Driver<Bool>
    let errorMessages: Driver<String>
    let showInventory: Observable<Inventory>
    let showOrder: Observable<OrderCollection>

    // MARK: - Lifecycle

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
                switch error {
                default:
                    return "There was a problem"
                }
            }
            .asDriver(onErrorJustReturn: "Other Error")
    }

}
