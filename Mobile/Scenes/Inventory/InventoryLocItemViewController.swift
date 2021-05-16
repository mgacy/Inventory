//
//  InventoryLocItemViewController.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import RxSwift

class InventoryLocItemViewController: MGTableViewController {

    // MARK: Properties

    var viewModel: InventoryLocItemViewModel!

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    deinit { log.debug("\(#function)") }

    // MARK: - View Methods

    override func setupView() {
        title = viewModel.windowTitle
        super.setupView()
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryLocItemViewController>!

    override func setupTableView() {
        tableView.register(cellType: SubItemTableViewCell.self)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 80
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - UITableViewDelegate Extension
extension InventoryLocItemViewController {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InventoryLocItemViewController: TableViewDataSourceDelegate {
    func configure(_ cell: SubItemTableViewCell, for locationItem: InventoryLocationItem) {
        let viewModel = InventoryLocItemCellViewModel(forLocationItem: locationItem)
        cell.configure(withViewModel: viewModel)
    }
}
