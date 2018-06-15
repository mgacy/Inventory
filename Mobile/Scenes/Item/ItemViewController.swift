//
//  ItemViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/7/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ItemViewController: MGTableViewController {

    private enum Strings {
        static let navTitle = "Items"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var bindings: ItemViewModel.Bindings {
        //let viewWillAppear =
        let refresh = refreshControl.rx.controlEvent(.valueChanged).asDriver()
        return ItemViewModel.Bindings(fetchTrigger: refresh,
                                      //addTaps: addButtonItem.rx.tap.asDriver(),
                                      //editTaps: editButtonItem.rx.tap.asDriver(),
                                      rowTaps: tableView.rx.itemSelected.asDriver())
    }

    var viewModel: ItemViewModel!

    // MARK: - Interface
    //let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    //let editButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)

    // MARK: - Lifecycle
    /*
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    */
    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    override func setupView() {
        super.setupView()
        title = Strings.navTitle
        extendedLayoutIncludesOpaqueBars = true
        //self.navigationItem.leftBarButtonItem =
        //self.navigationItem.rightBarButtonItem = addButtonItem
    }

    override func setupBindings() {
        // Activity Indicator
        viewModel.isRefreshing
            //.debug("isRefreshing")
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
        /*
        viewModel.hasRefreshed
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        */
        // Errors
        viewModel.errorMessages
            .delay(0.1)
            //.map { $0.localizedDescription }
            .drive(errorAlert)
            .disposed(by: disposeBag)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<ItemViewController>!

    override func setupTableView() {
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        tableView.register(cellType: SubItemTableViewCell.self)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - TableViewDelegate
extension ItemViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension ItemViewController: TableViewDataSourceDelegate {
    /*
    func canEdit(_ model: IndexPath) -> Bool {
        return true
    }
     */
    func configure(_ cell: SubItemTableViewCell, for item: Item) {
        let viewModel = ItemCellViewModel(forItem: item)
        cell.configure(withViewModel: viewModel)
    }

}
