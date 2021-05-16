//
//  InvoiceVendorViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class InvoiceVendorViewController: MGTableViewController {

    private enum Strings {
        static let navTitle = "Vendors"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var bindings: InvoiceVendorViewModel.Bindings {
        return InvoiceVendorViewModel.Bindings(rowTaps: tableView.rx.itemSelected.asDriver())
    }
    var viewModel: InvoiceVendorViewModel!

    // MARK: - Interface

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    deinit {
        log.debug("\(#function)")
    }

    // MARK: - View Methods

    override func setupView() {
        title = Strings.navTitle
        if #available(iOS 11, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        super.setupView()
    }

    override func setupBindings() {
        // Activity Indicator
        viewModel.fetching
            .drive(activityIndicatorView.rx.isAnimating)
            .disposed(by: disposeBag)

        viewModel.fetching
            .map { !$0 }
            .drive(activityIndicatorView.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.fetching
            .map { !$0 }
            .drive(messageLabel.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.showTable
            .map { !$0 }
            .drive(tableView.rx.isHidden)
            .disposed(by: disposeBag)
        /*
        // Errors
        viewModel.errors
            //.debug("Error:")
            .delay(0.1)
            .map { $0.localizedDescription }
            .drive(errorAlert)
            .disposed(by: disposeBag)
        */
        // Errors
        viewModel.errorMessages
            //.debug("Error:")
            .delay(0.1)
            .drive(errorAlert)
            //.drive(onNext: { [weak self] message in
            //    self?.showAlert(title: Strings.errorAlertTitle, message: message)
            //})
            .disposed(by: disposeBag)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceVendorViewController>!

    override func setupTableView() {
        tableView.register(cellType: UITableViewCell.self)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - UITableViewDelegate
extension InvoiceVendorViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate
extension InvoiceVendorViewController: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for invoice: Invoice) {
        cell.textLabel?.text = invoice.vendor?.name
        switch invoice.status {
        case InvoiceStatus.pending.rawValue:
            cell.textLabel?.textColor = ColorPalette.yellow
        case InvoiceStatus.completed.rawValue:
            cell.textLabel?.textColor = UIColor.black
        case InvoiceStatus.rejected.rawValue:
            /// TODO: what color should we use?
            cell.textLabel?.textColor = ColorPalette.red
            //cell.textLabel?.textColor = UIColor.black
        default:
            log.warning("\(#function) : invalid status for \(invoice)")
            cell.textLabel?.textColor = UIColor.lightGray
        }
    }

}
