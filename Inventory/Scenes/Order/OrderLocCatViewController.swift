//
//  OrderLocCatViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class OrderLocCatViewController: MGTableViewController {

    private enum Strings {
        static let navTitle = "Categories"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var bindings: OrderLocCatViewModel.Bindings {
        return OrderLocCatViewModel.Bindings(
            rowTaps: tableView.rx.itemSelected.asObservable()
        )
    }
    var viewModel: OrderLocCatViewModel!

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
        super.setupView()
        title = Strings.navTitle
        if #available(iOS 11, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        //self.navigationItem.leftBarButtonItem =
        //self.navigationItem.rightBarButtonItem =
    }

    //override func setupBindings() {}

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<OrderLocCatViewController>!

    override func setupTableView() {
        tableView.register(cellType: UITableViewCell.self)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - TableViewDelegate
extension OrderLocCatViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate
extension OrderLocCatViewController: TableViewDataSourceDelegate {
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
    func configure(_ cell: UITableViewCell, for location: OrderLocationCategory) {
        cell.textLabel?.text = location.name ?? "MISSING"
    }

}
