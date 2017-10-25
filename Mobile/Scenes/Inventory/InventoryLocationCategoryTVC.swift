//
//  InventoryLocationCategoryTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/9/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit

class InventoryLocationCategoryTVC: UITableViewController {

    // MARK: Properties

    var viewModel: InventoryLocCatViewModel!
    //let disposeBag = DisposeBag()

    // TableViewCell
    let cellIdentifier = "InventoryLocationCategoryTableViewCell"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.locationName
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - Navigation

    func showItemList(with category: InventoryLocationCategory) {
        let controller = InventoryLocationItemTVC.initFromStoryboard(name: "Main")
        controller.viewModel = InventoryLocItemViewModel(dataManager: viewModel.dataManager,
                                                         parentObject: .category(category))
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryLocationCategoryTVC>!

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCategory = dataSource.objectAtIndexPath(indexPath)
        showItemList(with: selectedCategory)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InventoryLocationCategoryTVC: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for locationCategory: InventoryLocationCategory) {
        cell.textLabel?.text = locationCategory.name

        switch locationCategory.status {
        case .notStarted:
            cell.textLabel?.textColor = UIColor.lightGray
        case .incomplete:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        case .complete:
            cell.textLabel?.textColor = UIColor.black
        }
    }

}
