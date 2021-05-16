//
//  OrderItemPhoneCell.swift
//  Mobile
//
//  Created by Mathew Gacy on 7/12/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit

final class OrderItemPhoneCell: SubItemTableViewCell {
    var viewModel: OrderItemPhoneCellViewModel!
}

extension OrderItemPhoneCell: OrderLocItemActionable {

    func increment() -> Bool {
        let result = viewModel.incrementOrder()
        if result {
            configure(withViewModel: viewModel)
        }
        return result
    }

    func decrement() -> Bool {
        let result = viewModel.decrementOrder()
        if result {
            configure(withViewModel: viewModel)
        }
        return result
    }

    func setToPar() -> Bool {
        let result = viewModel.setOrderToPar()
        if result {
            configure(withViewModel: viewModel)
        }
        return result
    }

    func setToZero() -> Bool {
        let result = viewModel.setOrderToZero()
        if result {
            configure(withViewModel: viewModel)
        }
        return result
    }

}
