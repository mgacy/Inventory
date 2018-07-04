//
//  InventoryLocCatViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/9/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import RxSwift

class InventoryLocCatViewController: MGTableViewController {

    // MARK: Properties

    var bindings: InventoryLocCatViewModel.Bindings {
        return InventoryLocCatViewModel.Bindings(rowTaps: tableView.rx.itemSelected.asDriver())
    }

    var viewModel: InventoryLocCatViewModel!

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    deinit { log.debug("\(#function)") }

    // MARK: - View Methods

    override func setupView() {
        title = viewModel.locationName
        super.setupView()
    }

    //override func setupBindings() {}

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryLocCatViewController>!

    override func setupTableView() {
        tableView.register(cellType: UITableViewCell.self)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - UITableViewDelegate Extension
extension InventoryLocCatViewController {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InventoryLocCatViewController: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for locationCategory: InventoryLocationCategory) {
        cell.textLabel?.text = locationCategory.name

        switch locationCategory.status {
        case .notStarted:
            cell.textLabel?.textColor = UIColor.lightGray
        case .incomplete:
            cell.textLabel?.textColor = ColorPalette.yellow
        case .complete:
            cell.textLabel?.textColor = UIColor.black
        }
    }

}
