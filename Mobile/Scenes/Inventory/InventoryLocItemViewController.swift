//
//  InventoryLocItemViewController.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import RxSwift

class InventoryLocItemViewController: UITableViewController {

    // MARK: Properties

    var viewModel: InventoryLocItemViewModel!
    let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.windowTitle
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    deinit { log.debug("\(#function)") }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryLocItemViewController>!

    fileprivate func setupTableView() {
        tableView.register(cellType: SubItemTableViewCell.self)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
