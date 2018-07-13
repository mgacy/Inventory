//
//  OrderLocItemViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/26/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class OrderLocItemViewController: MGTableViewController, OrderLocItemViewControllerType, OrderLocItemActionFactory {
    /*
    private enum Strings {
        static let navTitle = "NAME"
        static let errorAlertTitle = "Error"
    }
    */
    // MARK: - Properties

    var bindings: OrderLocItemViewModel.Bindings {
        return OrderLocItemViewModel.Bindings(
            //rowTaps: tableView.rx.itemSelected.asDriver()
            rowTaps: tableView.rx.itemSelected.asObservable()
        )
    }
    var viewModel: OrderLocItemViewModel!

    // MARK: - Interface

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    deinit { log.debug("\(#function)") }

    // MARK: - View Methods

    override func setupView() {
        title = viewModel.navTitle
        //self.navigationItem.leftBarButtonItem =
        //self.navigationItem.rightBarButtonItem =
        super.setupView()
    }

    //override func setupBindings() {}

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<OrderLocItemViewController>!

    override func setupTableView() {
        tableView.register(cellType: OrderLocItemPhoneCell.self)
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)

        // Other Delegate Methods
        tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }

}

// MARK: - TableViewDelegate
extension OrderLocItemViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: Swipe Actions

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) as? OrderLocItemActionable else {
            return nil
        }

        let setToZeroAction = makeSetToZeroAction(forCell: cell)
        let setToParAction = makeSetToParAction(forCell: cell)

        let swipeConfig = UISwipeActionsConfiguration(actions: [setToZeroAction, setToParAction])
        return swipeConfig
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) as? OrderLocItemActionable else {
            return nil
        }
        let decrementAction = makeDecrementAction(forCell: cell)
        let incrementAction = makeIncrementAction(forCell: cell)

        let swipeConfig = UISwipeActionsConfiguration(actions: [incrementAction, decrementAction])
        return swipeConfig
    }

}

// MARK: - TableViewDataSourceDelegate
extension OrderLocItemViewController: TableViewDataSourceDelegate {

    func canEdit(_ item: OrderLocationItem) -> Bool {
        return true
    }

    func configure(_ cell: OrderLocItemPhoneCell, for location: OrderLocationItem) {
        guard let orderItem = location.item else {
            log.error("Unable to get .orderItem for: \(location)")
            return
        }
        guard let cellViewModel = OrderItemCellViewModel(forOrderItem: orderItem) else {
            fatalError("\(#function) FAILED : unable to init view model for \(orderItem)")
        }
        cell.viewModel = cellViewModel
        cell.configure(withViewModel: cellViewModel)
    }

}
