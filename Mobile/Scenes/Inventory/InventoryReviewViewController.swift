//
//  InventoryReviewViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/11/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class InventoryReviewViewController: MGTableViewController {

    private enum Strings {
        static let navTitle = "Items"
        static let messageLabelText = "LOADING"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var bindings: InventoryReviewViewModel.Bindings {
        return InventoryReviewViewModel.Bindings(rowTaps: tableView.rx.itemSelected.asObservable())
    }

    var viewModel: InventoryReviewViewModel!

    // MARK: - Lifecycle

    //override func viewWillAppear(_ animated: Bool) {
    //    super.viewWillAppear(animated)
    //    self.tableView.reloadData()
    //}

    //override func didReceiveMemoryWarning() {}

    deinit { log.debug("\(#function)") }

    // MARK: - View Methods

    override func setupView() {
        super.setupView()
        title = Strings.navTitle
        /// TODO: add `messageLabel` output to viewModel?
        messageLabel.text = Strings.messageLabelText

        //self.navigationItem.leftBarButtonItem = self.editButtonItem
        //self.navigationItem.rightBarButtonItem = addButtonItem
    }

    override func setupBindings() {

        // Edit Button
        //editButtonItem.rx.tap
        //    .bind(to: viewModel.editTaps)
        //    .disposed(by: disposeBag)

        // Activity Indicator
        viewModel.isRefreshing
            .drive(activityIndicatorView.rx.isAnimating)
            .disposed(by: disposeBag)

        viewModel.isRefreshing
            .map { !$0 }
            .drive(activityIndicatorView.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.isRefreshing
            .map { !$0 }
            .drive(messageLabel.rx.isHidden)
            .disposed(by: disposeBag)
        /*
        viewModel.hasRefreshed
            /// TODO: use weak or unowned self?
            .drive(onNext: { [weak self] event in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
         */
        viewModel.showTable
            .map { !$0 }
            .drive(tableView.rx.isHidden)
            .disposed(by: disposeBag)

        // Errors
        viewModel.errorMessages
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryReviewViewController>!

    override func setupTableView() {
        //tableView.refreshControl = refreshControl
        tableView.register(cellType: SubItemTableViewCell.self)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView()
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - TableViewDelegate
extension InventoryReviewViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate
extension InventoryReviewViewController: TableViewDataSourceDelegate {
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
    func configure(_ cell: SubItemTableViewCell, for inventoryItem: InventoryItem) {
        let viewModel = InventoryReviewItemViewModel(forInventoryItem: inventoryItem)
        cell.configure(withViewModel: viewModel)
    }

}
