//
//  InventoryLocationItemTVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

enum LocationItemListParent {
    case category(InventoryLocationCategory)
    case location(InventoryLocation)

    var fetchPredicate: NSPredicate? {
        switch self {
        case .category(let category):
            return NSPredicate(format: "category == %@", category)
        case .location(let location):
            return NSPredicate(format: "location == %@", location)
        }
    }

}

class InventoryLocationItemTVC: UITableViewController {

    // MARK: Properties

    var viewModel: InventoryLocItemViewModel!

    // TableViewCell
    let cellIdentifier = "InventoryItemCell"

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.warning("\(#function)")
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    fileprivate func showKeypad(withIndexPath indexPath: IndexPath) {
        guard let controller = InventoryKeypadViewController.instance() else {
            fatalError("\(#function) FAILED : unable to get destination view controller.")
        }
        controller.viewModel = InventoryKeypadViewModel(dataManager: viewModel.dataManager, for: viewModel.parentObject,
                                                        atIndex: indexPath.row)
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryLocationItemTVC>!

    fileprivate func setupTableView() {
        tableView.register(SubItemTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //log.verbose("Selected InventoryLocationItem: \(dataSource.objectAtIndexPath(indexPath))")
        showKeypad(withIndexPath: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InventoryLocationItemTVC: TableViewDataSourceDelegate {
    func configure(_ cell: SubItemTableViewCell, for locationItem: InventoryLocationItem) {
        let viewModel = InventoryLocItemCellViewModel(forLocationItem: locationItem)
        cell.configure(withViewModel: viewModel)
    }
}
