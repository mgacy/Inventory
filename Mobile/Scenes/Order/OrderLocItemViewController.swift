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

class OrderLocItemViewController: MGTableViewController {
    /*
    private enum Strings {
        static let navTitle = "NAME"
        static let errorAlertTitle = "Error"
    }
    */
    // MARK: - Properties

    var bindings: OrderLocItemViewModel.Bindings {
        /*
        let viewWillAppear = rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        let refresh = refreshControl.rx
            .controlEvent(.valueChanged)
            .asDriver()
        */
        return OrderLocItemViewModel.Bindings(
            //fetchTrigger: Driver.merge(viewWillAppear, refresh),
            fetchTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver(),
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

    override func setupBindings() {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            setupBindingsForPhone()
        case .pad:
            setupBindingsForPad()
        default:
            fatalError("Unable to setup bindings for unrecognized device: \(UIDevice.current.userInterfaceIdiom)")
        }
    }

    // MARK: iPad
    private func setupBindingsForPad() {

        // Setup numberFormatter
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.maximumFractionDigits = 2
        /*
        // TableView
        viewModel.items
            // closure args are row (IndexPath), element, cell
            // wiftlint:disable:next line_length
            .bind(to: tableView.rx.items(cellIdentifier: StepperTableViewCell.reuseID, cellType: StepperTableViewCell.self)) { (_, element, cell: StepperTableViewCell) in
                // wiftlint:disable:next line_length
                guard let cellViewModel = StepperCellViewModel(forOrderItem: element, bindings: cell.bindings, numberFormatter: numberFormatter) else {
                    fatalError("\(#function) FAILED : unable to init view model for \(element)")
                }
                cell.bind(to: cellViewModel)
            }
            .disposed(by: disposeBag)
        */
        // Other Delegate Methods
        //tableView.rx
        //    .setDelegate(self)
        //    .disposed(by: disposeBag)
    }

    private func setupBindingsForPhone() {
        /*
        // TableView
        viewModel.items
            // closure args are row (IndexPath), element, cell
            // wiftlint:disable:next line_length
            .bind(to: tableView.rx.items(cellIdentifier: SubItemTableViewCell.reuseID, cellType: SubItemTableViewCell.self)) { (_, element, cell: SubItemTableViewCell) in
                guard let cellViewModel = OrderItemCellViewModel(forOrderItem: element) else {
                    fatalError("\(#function) FAILED : unable to init view model for \(element)")
                }
                cell.configure(withViewModel: cellViewModel)
            }
            .disposed(by: disposeBag)
        */
        // Other Delegate Methods
        //tableView.rx
        //    .setDelegate(self)
        //    .disposed(by: disposeBag)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<OrderLocItemViewController>!

    override func setupTableView() {
        //tableView.refreshControl = refreshControl
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            setupTableViewForPhone()
        case .pad:
            setupTableViewForPad()
        default:
            fatalError("Device is neither phone nor pad")
        }
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

    private func setupTableViewForPad() {
        tableView.register(cellType: StepperTableViewCell.self)
    }

    private func setupTableViewForPhone() {
        tableView.register(cellType: SubItemTableViewCell.self)
    }

}

// MARK: - TableViewDelegate
extension OrderLocItemViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - UITableViewDelegate (Swipe Actions)

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let setToZeroAction = makeSetToZeroAction(forRowAtIndexPath: indexPath)
        let setToParAction = makeSetToParAction(forRowAtIndexPath: indexPath)
        let swipeConfig = UISwipeActionsConfiguration(actions: [setToZeroAction, setToParAction])
        return swipeConfig
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let incrementAction = makeIncrementAction(forRowAtIndexPath: indexPath)
        let decrementAction = makeDecrementAction(forRowAtIndexPath: indexPath)
        let swipeConfig = UISwipeActionsConfiguration(actions: [incrementAction, decrementAction])
        return swipeConfig
    }

    // MARK: - Contextual Action Factory Methods

    @available(iOS 11.0, *)
    func makeDecrementAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "- 1") { [weak self] _, _, completionHandler in
            let result = self?.viewModel.decrementOrder(forRowAtIndexPath: indexPath) ?? false
            if result {
                self?.tableView.reloadRows(at: [indexPath], with: .fade)
            }
            completionHandler(result)
        }
        //action.image = UIImage(named: "")
        action.backgroundColor = ColorPalette.blue
        return action
    }

    @available(iOS 11.0, *)
    func makeIncrementAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "+ 1") { [weak self] _, _, completionHandler in
            let result = self?.viewModel.incrementOrder(forRowAtIndexPath: indexPath) ?? false
            if result {
                self?.tableView.reloadRows(at: [indexPath], with: .fade)
            }
            completionHandler(result)
        }
        //action.image = UIImage(named: "")
        action.backgroundColor = ColorPalette.lazur
        return action
    }

    @available(iOS 11.0, *)
    func makeSetToZeroAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "0") { [weak self] _, _, completionHandler in
            let result = self?.viewModel.setOrderToZero(forRowAtIndexPath: indexPath) ?? false
            if result {
                self?.tableView.reloadRows(at: [indexPath], with: .fade)
            }
            completionHandler(result)
        }
        //action.image = UIImage(named: "")
        action.backgroundColor = ColorPalette.blue
        return action
    }

    @available(iOS 11.0, *)
    func makeSetToParAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Par") { [weak self] _, _, completionHandler in
            let result = self?.viewModel.setOrderToPar(forRowAtIndexPath: indexPath) ?? false
            if result {
                self?.tableView.reloadRows(at: [indexPath], with: .fade)
            }
            completionHandler(result)
        }
        //action.image = UIImage(named: "")
        action.backgroundColor = ColorPalette.navy
        return action
    }

}

// MARK: - TableViewDataSourceDelegate
extension OrderLocItemViewController: TableViewDataSourceDelegate {
    /*
    func canEdit(_ collection: InvoiceCollection) -> Bool {
        switch collection.uploaded {
        case true:
            return false
        case false:
            return true
        }
    }
    */
    func configure(_ cell: SubItemTableViewCell, for location: OrderLocationItem) {
        guard let orderItem = location.item else {
            log.error("Unable to get .orderItem for: \(location)")
            return
        }
        guard let cellViewModel = OrderItemCellViewModel(forOrderItem: orderItem) else {
            fatalError("\(#function) FAILED : unable to init view model for \(orderItem)")
        }
        cell.configure(withViewModel: cellViewModel)
    }
    /*
    func configure(_ cell: StepperTableViewCell, for location: OrderLocationItem) {
        //cell.textLabel?.text = location.name ?? "MISSING"
        guard let orderItem = location.item else {
            return
        }

        // Setup numberFormatter
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.maximumFractionDigits = 2

        guard let cellViewModel = StepperCellViewModel(forOrderItem: orderItem, bindings: cell.bindings, numberFormatter: numberFormatter) else {
            fatalError("\(#function) FAILED : unable to init view model for \(location)")
        }
        cell.bind(to: cellViewModel)
    }
    */
}
