//
//  OrderLocItemProtocols.swift
//  Mobile
//
//  Created by Mathew Gacy on 7/12/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit

/// NOTE: this follows part of `AttachableType`
protocol OrderLocItemViewControllerType {
    var viewModel: OrderLocItemViewModel! { get set }
    var bindings: OrderLocItemViewModel.Bindings { get }
    var tableView: UITableView { get }
}

protocol OrderLocItemActionable {
    func increment() -> Bool
    func decrement() -> Bool
    func setToPar() -> Bool
    func setToZero() -> Bool
}

@available(iOS 11.0, *)
protocol OrderLocItemActionFactory: class {
    func makeDecrementAction(forCell cell: OrderLocItemActionable) -> UIContextualAction
    func makeIncrementAction(forCell cell: OrderLocItemActionable) -> UIContextualAction
    func makeSetToZeroAction(forCell cell: OrderLocItemActionable) -> UIContextualAction
    func makeSetToParAction(forCell cell: OrderLocItemActionable) -> UIContextualAction
}

@available(iOS 11.0, *)
extension OrderLocItemActionFactory where Self: OrderLocItemViewControllerType {

    func makeDecrementAction(forCell cell: OrderLocItemActionable) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "- 1") { _, _, completionHandler in
            let result = cell.decrement()
            completionHandler(result)
        }
        //action.image = UIImage(named: "")
        action.backgroundColor = ColorPalette.blue
        return action
    }

    func makeIncrementAction(forCell cell: OrderLocItemActionable) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "+ 1") { _, _, completionHandler in
            let result = cell.increment()
            completionHandler(result)
        }
        //action.image = UIImage(named: "")
        action.backgroundColor = ColorPalette.lazur
        return action
    }

    func makeSetToZeroAction(forCell cell: OrderLocItemActionable) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "0") { _, _, completionHandler in
            let result = cell.setToZero()
            completionHandler(result)
        }
        //action.image = UIImage(named: "")
        action.backgroundColor = ColorPalette.blue
        return action
    }

    func makeSetToParAction(forCell cell: OrderLocItemActionable) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Par") { _, _, completionHandler in
            let result = cell.setToPar()
            completionHandler(result)
        }
        //action.image = UIImage(named: "")
        action.backgroundColor = ColorPalette.navy
        return action
    }

}
