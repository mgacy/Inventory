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

    // MARK: Public
    let state: Driver<ItemState>
    let nameColor: Driver<UIColor>
    let nameText: Driver<String>
    let packText: Driver<String>
    //
    let parText: String
    let parUnit: CurrentUnit
    let recommendedText: String
    let recommendedUnit: CurrentUnit
    /*
    var nameText: String { return item.name ?? "Error" }
    var nameColor: UIColor { return self.status.associatedColor }

    var packText: String { return item.packDisplay }

    var quantityColor: UIColor { return self.status.associatedColor }
    var quantityText: String {
        /// TODO: simply use `switch status {}`?
        guard self.status != .inactive else {
            return ""
        }
        guard let quantity = orderItem.quantity else {
            return "Error"
        }
        return "\(quantity)"
    }
    */
    // MARK: - Lifecycle

    init?(forOrderItem orderItem: OrderItem, bindings: Bindings, numberFormatter: NumberFormatter) {
        self.numberFormatter = numberFormatter
        self.orderItem = orderItem
        guard let item = orderItem.item else { return nil }
        self.item = item

        self.nameColor = Driver.just(UIColor.black)
        self.nameText = Driver.just(item.name ?? "Error")

        self.packText = Driver.just(item.packDisplay)

        self.parText = numberFormatter.string(from: NSNumber(value: orderItem.par)) ?? "Error"
        self.parUnit = CurrentUnit(for: item, from: orderItem.parUnit)

        self.recommendedText = numberFormatter.string(from: NSNumber(value: orderItem.minOrder)) ?? "Error"
        self.recommendedUnit = CurrentUnit(for: item, from: orderItem.minOrderUnit)

        let initialState = ItemState(item: orderItem)
        self.state = bindings.commands.scan(initialState, accumulator: ItemState.reduce)
            //.distinctUntilChanged()
            .startWith(initialState)
    }

    // MARK: -

    struct Dependency {
        let orderItem: OrderItem
    }

    struct Bindings {
        let commands: Driver<StepperCommand>
    }

}
