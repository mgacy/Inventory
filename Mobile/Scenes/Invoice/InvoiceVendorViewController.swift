//
//  InvoiceVendorViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import RxCocoa
import RxSwift

class InvoiceVendorViewController: UITableViewController {

    private enum Strings {
        static let navTitle = "Vendors"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var viewModel: InvoiceVendorViewModel!
    let disposeBag = DisposeBag()
    //let selectedObjects = PublishSubject<Invoice>()

    // TableViewCell
    let cellIdentifier = "Cell"

    // MARK: - Interface

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        title = Strings.navTitle
    }

    //private func setupConstraints() {}

    //private func setupBindings() {}

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceVendorViewController>!

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }

    // MARK: - Navigation

    fileprivate func showInvoice(withInvoice invoice: Invoice) {
        let vc = InvoiceItemViewController.initFromStoryboard(name: "Main")
        vc.parentObject = invoice
        vc.managedObjectContext = viewModel.dataManager.managedObjectContext
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedObject = dataSource.objectAtIndexPath(indexPath)
        log.verbose("Selected Invoice: \(selectedObject)")
        showInvoice(withInvoice: selectedObject)
        //selectedObjects.onNext(selectedObject)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InvoiceVendorViewController: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for invoice: Invoice) {
       cell.textLabel?.text = invoice.vendor?.name

        switch invoice.uploaded {
        case false:
            //cell.textLabel?.textColor = UIColor.lightGray
            cell.textLabel?.textColor = ColorPalette.yellowColor
        case true:
            cell.textLabel?.textColor = UIColor.black
        }
    }

}
