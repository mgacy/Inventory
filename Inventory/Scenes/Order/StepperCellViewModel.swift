//
//  StepperCellViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 3/28/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

final class StepperCellViewModel {

    // MARK: - Properties

    let state: Driver<ItemState>
    let nameColor: UIColor
    let nameText: String
    let packText: String
    //var nameColor: UIColor { return self.status.associatedColor }
    //var nameText: String { return item.name ?? "Error" }
    //var packText: String { return item.packDisplay }
    let parText: String
    let parUnit: CurrentUnit
    let recommendedText: String
    let recommendedUnit: CurrentUnit
    //var quantityColor: UIColor { return self.status.associatedColor }

    // MARK: Private
    private let numberFormatter: NumberFormatter
    private let orderItem: OrderItem
    private let item: Item
    private var status: ItemStatus {
        guard let quantity = orderItem.quantity else {
            return .warning
        }
        if quantity.doubleValue > 0.0 {
            return .normal
        } else {
            return .inactive
        }
    }

    // MARK: - Lifecycle

    init?(forOrderItem orderItem: OrderItem, bindings: Bindings, numberFormatter: NumberFormatter) {
        self.numberFormatter = numberFormatter
        self.orderItem = orderItem
        guard let item = orderItem.item else { return nil }
        self.item = item
        // Name
        self.nameColor = UIColor.black
        self.nameText = item.name ?? "Error"
        // Pack
        self.packText = item.packDisplay
        // Par
        self.parText = numberFormatter.string(from: NSNumber(value: orderItem.par)) ?? "Error"
        self.parUnit = CurrentUnit(for: item, from: orderItem.parUnit)
        // Recommended
        self.recommendedText = numberFormatter.string(from: NSNumber(value: orderItem.minOrder)) ?? "Error"
        self.recommendedUnit = CurrentUnit(for: item, from: orderItem.minOrderUnit)

        let initialState = ItemState(item: orderItem)
        self.state = bindings.commands.scan(initialState, accumulator: ItemState.reduce)
            //.distinctUntilChanged()
            .startWith(initialState)
    }

    // MARK: -

    struct Bindings {
        let commands: Driver<StepperCommand>
    }

    /*
    init?(forOrderItem orderItem: OrderItem, numberFormatter: NumberFormatter) {
        self.numberFormatter = numberFormatter
        self.orderItem = orderItem
        guard let item = orderItem.item else { return nil }
        self.item = item
        /// Name
        //self.nameColor = Driver.just(UIColor.black)
        //self.nameText = Driver.just(item.name ?? "Error")
        /// Pack
        //self.packText = Driver.just(item.packDisplay)
        /// Par
        self.parText = numberFormatter.string(from: NSNumber(value: orderItem.par)) ?? "Error"
        self.parUnit = CurrentUnit(for: item, from: orderItem.parUnit)
        /// Recommended
        self.recommendedText = numberFormatter.string(from: NSNumber(value: orderItem.minOrder)) ?? "Error"
        self.recommendedUnit = CurrentUnit(for: item, from: orderItem.minOrderUnit)

        /*
        let initialState = ItemState(item: orderItem)
        self.state = bindings.commands.scan(initialState, accumulator: ItemState.reduce)
            //.distinctUntilChanged()
            .startWith(initialState)
        */
    }

    func transform(input: Input) -> Output {
        let initialState = ItemState(item: orderItem)
        return input.scan(initialState, accumulator: ItemState.reduce)
            //.distinctUntilChanged()
            .startWith(initialState)
    }

    // MARK: -

    typealias Input = Driver<StepperCommand>
    typealias Output = Driver<ItemState>
    */
}

// MARK: - Swipe Actions
extension StepperCellViewModel {

    func setOrderToPar() -> Bool {
        guard let parUnit = orderItem.parUnit else {
            return false
        }
        // TODO: should we return false if orderItem.par == 0?
        let newQuantity = orderItem.par.rounded(.awayFromZero)

        orderItem.quantity = newQuantity as NSNumber
        orderItem.orderUnit = parUnit
        return true
    }

    func setOrderToZero() -> Bool {
        orderItem.quantity = 0
        return true
    }

}
