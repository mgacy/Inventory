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
    //let quantityColor: Driver<String>
    //let quantityText: Driver<String>
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

    var unitColor: UIColor { return self.status.associatedColor }
    var unitText: String {
        switch status {
        case .inactive:
            return ""
        case .normal:
            return orderItem.orderUnit?.abbreviation ?? ""
        case .pending:
            return orderItem.orderUnit?.abbreviation ?? ""
        case .warning:
            return ""
        }
    }
    */
    // MARK: - Lifecycle

    init?(forOrderItem orderItem: OrderItem, bindings: Bindings) {
        self.orderItem = orderItem
        guard let item = orderItem.item else { return nil }
        self.item = item

        self.nameColor = Driver.just(UIColor.black)
        self.nameText = Driver.just(item.name ?? "Error")

        self.packText = Driver.just(item.packDisplay)

        let state0 = ItemState(value: Int(truncating: orderItem.quantity ?? 0.0),
                               //packSize: Int(item.packSize ?? Int16(0)),
                               packSize: Int(item.packSize),
                               currentUnit: .packUnit)

        self.state = bindings.commands.scan(state0, accumulator: ItemState.reduce)
            //.distinctUntilChanged()
            .filter { $0.stepperState != StepperState.stable }
            .do(onNext: { state in
                print("\n\(state)")
                guard state.stepperState != .maximum, state.stepperState != .minimum else {
                    return
                }
                //print("BEFORE: \(orderItem.quantity)")
                orderItem.quantity = state.value as NSNumber
                //print("AFTER: \(orderItem.quantity)")
            })
            .startWith(state0)
    }

    // MARK: -

    struct Dependency {
        let orderItem: OrderItem
    }

    struct Bindings {
        let commands: Driver<StepperCommand>
        //let stepperState: Driver<ItemState>
    }

}
