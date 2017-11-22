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

final class HomeViewModel: ViewModelType {

    struct Input {
        let addInventoryTaps: Observable<Void>
        let addOrderTaps: Observable<NewOrderGenerationMethod>
    }

    struct Output {
        let storeName: Driver<String>
        let isLoading: Driver<Bool>
        let errorMessages: Driver<String>
        let showInventory: Driver<Inventory>
        //let createInventoryResults: Observable<Event<Inventory>>
        let showOrder: Observable<OrderCollection>
        //let createOrderResults: Observable<Event<OrderCollection>>
    }

    // MARK: Dependencies
    let dataManager: DataManager

    // MARK: - Lifecycle

    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }

    func transform(input: Input) -> Output {

        // FIXME: actually get this from somewhere
        let storeName = Observable.just("Lux").asDriver(onErrorJustReturn: "")

        // Loading
        let isLoading = ActivityIndicator()

        // Inventory
        let createInventoryResults = input.addInventoryTaps
            .throttle(0.5, scheduler: MainScheduler.instance)
            .flatMap { _ -> Observable<Event<Inventory>> in
                return self.dataManager.createInventory()
                    .trackActivity(isLoading)
            }
            .share()

        // Order
        let createOrderResults = input.addOrderTaps
            .throttle(0.5, scheduler: MainScheduler.instance)
            .flatMap { method -> Observable<Event<OrderCollection>> in
                return self.dataManager.createOrderCollection(generationMethod: method, returnUsage: false)
                    .trackActivity(isLoading)
            }
            .share()

        // Errors
        let errorMessages = Observable.of(createInventoryResults.errors(), createOrderResults.errors())
            .merge()
            .map { error in
                log.debug("\(#function) ERROR : \(error)")
                switch error {
                default:
                    return "There was a problem"
                }
            }
            .asDriver(onErrorJustReturn: "Other Error")

        // Output
        return Output(
            storeName: storeName,
            isLoading: isLoading.asDriver(),
            errorMessages: errorMessages,
            showInventory: createInventoryResults.elements().asDriver(onErrorDriveWith: .never()),
            //createInventoryResults: createInventoryResults,
            showOrder: createOrderResults.elements())
            //createOrderResults: createOrderResults
    }

}
