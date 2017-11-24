//
//  InventoryLocationItemTVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import RxSwift

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
    let disposeBag = DisposeBag()

    let selectedIndices: Observable<IndexPath>
    fileprivate let _selectedIndices = PublishSubject<IndexPath>()

    // TableViewCell
    let cellIdentifier = "InventoryItemCell"

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        self.selectedIndices = _selectedIndices.asObservable()
        super.init(coder: aDecoder)
    }

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
        _selectedIndices.onNext(indexPath)
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
