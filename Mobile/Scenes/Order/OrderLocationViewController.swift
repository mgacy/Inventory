//
//  OrderLocationViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class OrderLocationViewController: MGTableViewController {

    private enum Strings {
        static let navTitle = "Locations"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var bindings: OrderLocationViewModel.Bindings {
        /*
        let viewWillAppear = rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        let refresh = refreshControl.rx
            .controlEvent(.valueChanged)
            .asDriver()
        */
        return OrderLocationViewModel.Bindings(
            //fetchTrigger: Driver.merge(viewWillAppear, refresh),
            fetchTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver(),
            //rowTaps: tableView.rx.itemSelected.asDriver()
            rowTaps: tableView.rx.itemSelected.asObservable()
        )
    }
    var viewModel: OrderLocationViewModel!

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

    override func setupBindings() {

        // Activity Indicator
        viewModel.isRefreshing
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        /// TODO: there is an ActivityIndicator property we can set so it automatically hides when stopped
        viewModel.isRefreshing
            .map { !$0 }
            .drive(activityIndicatorView.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.isRefreshing
            .map { !$0 }
            .drive(messageLabel.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.showTable
            .map { !$0 }
            .do(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
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
    fileprivate var dataSource: TableViewDataSource<OrderLocationViewController>!

    override func setupTableView() {
        tableView.refreshControl = refreshControl
        tableView.register(cellType: UITableViewCell.self)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - TableViewDelegate
extension OrderLocationViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate
extension OrderLocationViewController: TableViewDataSourceDelegate {
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
    func configure(_ cell: UITableViewCell, for location: OrderLocation) {
        cell.textLabel?.text = location.name ?? "MISSING"
    }

}
