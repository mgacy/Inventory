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

class OrderLocItemViewController: UIViewController {
    /*
    private enum Strings {
        static let navTitle = "NAME"
        static let errorAlertTitle = "Error"
    }
    */
    // MARK: - Properties

    var viewModel: OrderLocItemViewModel!
    let disposeBag = DisposeBag()

    // MARK: - Interface
    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()

        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            setupBindings()
        case .pad:
            setupBindingsForIpad()
        default:
            fatalError("Unable to setup bindings for unrecognized device: \(UIDevice.current.userInterfaceIdiom)")
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        title = viewModel.navTitle
        //self.navigationItem.leftBarButtonItem =
        //self.navigationItem.rightBarButtonItem =

        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            tableView.register(cellType: SubItemTableViewCell.self)
        case .pad:
            tableView.register(cellType: StepperTableViewCell.self)
        default:
            fatalError("Device is neither phone nor pad")
        }
        tableView.tableFooterView = UIView()
        self.view.addSubview(tableView)
    }

    private func setupConstraints() {
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    private func setupBindings() {
        // TableView
        viewModel.items
            // closure args are row (IndexPath), element, cell
            // swiftlint:disable:next line_length
            .bind(to: tableView.rx.items(cellIdentifier: SubItemTableViewCell.reuseID, cellType: SubItemTableViewCell.self)) { (_, element, cell: SubItemTableViewCell) in
                guard let cellViewModel = OrderItemCellViewModel(forOrderItem: element) else {
                    fatalError("\(#function) FAILED : unable to init view model for \(element)")
                }
                cell.configure(withViewModel: cellViewModel)
            }
            .disposed(by: disposeBag)

        // Other Delegate Methods
        tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }

    // MARK: iPad
    private func setupBindingsForIpad() {

        // Setup numberFormatter
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.maximumFractionDigits = 2

        // TableView
        viewModel.items
            // closure args are row (IndexPath), element, cell
            // swiftlint:disable:next line_length
            .bind(to: tableView.rx.items(cellIdentifier: StepperTableViewCell.reuseID, cellType: StepperTableViewCell.self)) { (_, element, cell: StepperTableViewCell) in
                // swiftlint:disable:next line_length
                guard let cellViewModel = StepperCellViewModel(forOrderItem: element, bindings: cell.bindings, numberFormatter: numberFormatter) else {
                    fatalError("\(#function) FAILED : unable to init view model for \(element)")
                }
                cell.bind(to: cellViewModel)
            }
            .disposed(by: disposeBag)

        // Other Delegate Methods
        tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }

}

// MARK: - UITableViewDelegate (Swipe Actions)
@available(iOS 11.0, *)
extension OrderLocItemViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let setToZeroAction = contextualSetToZeroAction(forRowAtIndexPath: indexPath)
        let setToParAction = contextualSetToParAction(forRowAtIndexPath: indexPath)
        let swipeConfig = UISwipeActionsConfiguration(actions: [setToZeroAction, setToParAction])
        return swipeConfig
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let incrementAction = contextualIncrementAction(forRowAtIndexPath: indexPath)
        let decrementAction = contextualDecrementAction(forRowAtIndexPath: indexPath)
        let swipeConfig = UISwipeActionsConfiguration(actions: [incrementAction, decrementAction])
        return swipeConfig
    }

    // MARK: - Contextual Actions

    func contextualDecrementAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
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

    func contextualIncrementAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
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

    func contextualSetToZeroAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
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

    func contextualSetToParAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
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
