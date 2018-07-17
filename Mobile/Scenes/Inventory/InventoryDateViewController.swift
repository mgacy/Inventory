//
//  InventoryDateViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import PKHUD
import RxCocoa
import RxSwift

class InventoryDateViewController: MGTableViewController {

    private enum Strings {
        static let navTitle = "Inventories"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var bindings: InventoryDateViewModel.Bindings {
        //let viewWillAppear = ...
        let refresh = refreshControl.rx.controlEvent(.valueChanged).asDriver()
        return InventoryDateViewModel.Bindings(
            fetchTrigger: refresh,
            addTaps: addButtonItem.rx.tap.asDriver(),
            rowTaps: tableView.rx.itemSelected.asObservable()
        )
    }
    var viewModel: InventoryDateViewModel!

    // MARK: - Interface
    let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    override func setupView() {
        title = Strings.navTitle
        //self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.navigationItem.rightBarButtonItem = addButtonItem
        extendedLayoutIncludesOpaqueBars = true

        if #available(iOS 11, *) {
            navigationItem.largeTitleDisplayMode = .always
        }
        super.setupView()
    }

    override func setupBindings() {

        // Activity Indicator
        viewModel.isRefreshing
            //.debug("isRefreshing")
            .delay(0.01)
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
        /*
        viewModel.hasRefreshed
            //.debug("hasRefreshed")
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        */
        // Errors
        viewModel.errorMessages
            .delay(0.1)
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryDateViewController>!

    override func setupTableView() {
        tableView.refreshControl = refreshControl
        tableView.register(cellType: UITableViewCell.self)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - TableViewDelegate
extension InventoryDateViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate
extension InventoryDateViewController: TableViewDataSourceDelegate {

    func canEdit(_ inventory: Inventory) -> Bool {
        switch inventory.uploaded {
        case true:
            return false
        case false:
            return true
        }
    }

    func configure(_ cell: UITableViewCell, for inventory: Inventory) {
        cell.textLabel?.text = Date(timeIntervalSinceReferenceDate: inventory.dateTimeInterval).altStringFromDate()
        switch inventory.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.yellow
        }
    }

}
