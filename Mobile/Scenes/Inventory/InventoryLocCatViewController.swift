//
//  InventoryLocCatViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/9/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import RxSwift

class InventoryLocCatViewController: UITableViewController {

    // MARK: Properties

    var viewModel: InventoryLocCatViewModel!
    let disposeBag = DisposeBag()

    let selectedObjects: Observable<InventoryLocationCategory>
    fileprivate let _selectedObjects = PublishSubject<InventoryLocationCategory>()

    // TableViewCell
    let cellIdentifier = "InventoryLocationCategoryTableViewCell"

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        self.selectedObjects = _selectedObjects.asObservable()
        super.init(coder: aDecoder)
    }

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

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryLocCatViewController>!

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        _selectedObjects.onNext(dataSource.objectAtIndexPath(indexPath))
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
