//
//  InvoiceItemTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import PKHUD
import RxCocoa
import RxSwift

class InvoiceItemViewController: UITableViewController {

    private enum Strings {
        //static let navTitle
        static let errorAlertTitle = "Error"
        // Actions
        static let alertMessage = "Why wasn't this item received?"
        //static let notReceivedActionTitle = "Not Received ..."
        //static let moreActionTitle = "More"
        //static let receivedActionTitle = "Received"
        //static let damagedActionTitle = "Damaged"
        //static let outOfStockActionTitle = "Out of Stock"
        //static let wrongItemActionTitle = "Wrong Item"
        //static let cancelActionTitle = "Cancel"
    }

    // MARK: - Properties

    var viewModel: InvoiceItemViewModel!
    let disposeBag = DisposeBag()

    let selectedObjects = PublishSubject<InvoiceItem>()

    // Interface
    let uploadButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Upload"), style: UIBarButtonItemStyle.plain, target: nil, action: nil)

    // TableView
    var cellIdentifier = "InvoiceItemCell"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupBindings()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    func setupView() {
        title = viewModel.vendorName
        self.navigationItem.rightBarButtonItem = uploadButtonItem
    }

    func setupBindings() {

        // Uploading
        viewModel.isUploading
            .filter { $0 }
            .drive(onNext: { _ in
                HUD.show(.progress)
            })
            .disposed(by: disposeBag)

        viewModel.uploadResults
            .subscribe(onNext: { [weak self] result in
                switch result.event {
                case .next:
                    HUD.flash(.success, delay: 1.0) { _ in
                        /// TODO: handle this elsewhere
                        self?.navigationController!.popViewController(animated: true)
                    }
                case .error:
                    /// TODO: `case.error(let error):; switch error {}`
                    UIViewController.showErrorInHUD(title: Strings.errorAlertTitle, subtitle: "Message")
                case .completed:
                    log.warning("\(#function) : not sure how to handle completion")
                }
            })
            .disposed(by: disposeBag)

        // Errors
        // Selection
    }

    // MARK: - Navigation

    fileprivate func showKeypad(withIndexPath indexPath: IndexPath) {
        guard let destinationController = InvoiceKeypadViewController.instance() else {
            fatalError("\(#function) FAILED: unable to get destination view controller.")
        }
        /// TODO: pass DataManager
        let managedObjectContext = viewModel.dataManager.managedObjectContext
        destinationController.viewModel = InvoiceKeypadViewModel(for: viewModel.parentObject, atIndex: indexPath.row,
                                                                 inContext: managedObjectContext)
        navigationController?.pushViewController(destinationController, animated: true)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceItemViewController>!

    fileprivate func setupTableView() {
        tableView.register(SubItemTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 80
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //log.verbose("Selected InvoiceItem: \(dataSource.objectAtIndexPath(indexPath))")
        showKeypad(withIndexPath: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        /*
         let invoiceItem = dataSource.objectAtIndexPath(indexPath)

        // More Button
        let more = UITableViewRowAction(style: .normal, title: "More") { action, index in
            self.isEditing = false
            log.info("more button tapped")
        }
        more.backgroundColor = UIColor.lightGray
        */
        // Not Received Button
        let notReceived = UITableViewRowAction(style: .normal, title: "Not Received ...") { _, indexPath in
            //self.showNotReceivedAlert(forItem: invoiceItem)
            self.showNotReceivedAlert(forItemAt: indexPath)
        }
        notReceived.backgroundColor = ColorPalette.redColor

        // Received Button
        let received = UITableViewRowAction(style: .normal, title: "Received") { [weak self] _, indexPath in
            /// TODO: do we not need to handle setting `self.isEditing = false`?
            self?.viewModel.updateItemStatus(forItemAt: indexPath, withStatus: .received) //{ self?.isEditing = false }
        }
        received.backgroundColor = ColorPalette.navyColor

        return [received, notReceived]
    }

}

// MARK: - Alert Controller Extension
extension InvoiceItemViewController {

    func showNotReceivedAlert(forItemAt indexPath: IndexPath) {

        // Alert Controller
        /// FIXME: use adaptive stype
        let alertController = UIAlertController(title: nil, message: Strings.alertMessage, preferredStyle: .actionSheet)

        // Actions

        /// TODO: use InvoiceItemStatus.description for alert action title?

        // damaged
        alertController.addAction(UIAlertAction(title: "Damaged", style: .default, handler: { [weak self] (_) in
            self?.viewModel.updateItemStatus(forItemAt: indexPath, withStatus: .damaged) //{ self?.isEditing = false }
        }))

        // outOfStock
        alertController.addAction(UIAlertAction(title: "Out of Stock", style: .default, handler: { [weak self] (_) in
            self?.viewModel.updateItemStatus(forItemAt: indexPath, withStatus: .outOfStock)
        }))

        // wrongItem
        alertController.addAction(UIAlertAction(title: "Wrong Item", style: .default, handler: { [weak self] (_) in
            self?.viewModel.updateItemStatus(forItemAt: indexPath, withStatus: .wrongItem)
        }))

        // cancel
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            self.isEditing = false
        }))

        // Present Alert
        present(alertController, animated: true, completion: nil)
    }
    /*
    func showNotReceivedAlert(forItem invoiceItem: InvoiceItem) {

        // Generic Action Handler

        func updateItemStatus(forItem invoiceItem: InvoiceItem, withStatus status: InvoiceItemStatus) {
            self.isEditing = false
            invoiceItem.status = status.rawValue
            //managedObjectContext?.performSaveOrRollback()
            log.info("Updated InvoiceItem: \(invoiceItem)")
        }

        // Alert Controller
        let alertController = UIAlertController(title: nil, message: "Why wasn't this item received?",
                                                preferredStyle: .actionSheet)

        // Actions

        /// TODO: use InvoiceItemStatus.description for alert action title?

        // damaged
        alertController.addAction(UIAlertAction(title: "Damaged", style: .default, handler: { (_) in
            updateItemStatus(forItem: invoiceItem, withStatus: .damaged)
        }))

        // outOfStock
        alertController.addAction(UIAlertAction(title: "Out of Stock", style: .default, handler: { (_) in
            updateItemStatus(forItem: invoiceItem, withStatus: .outOfStock)
        }))

        // wrongItem
        alertController.addAction(UIAlertAction(title: "Wrong Item", style: .default, handler: { (_) in
            updateItemStatus(forItem: invoiceItem, withStatus: .wrongItem)
        }))

        // cancel
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            self.isEditing = false
        }))

        // Present Alert
        present(alertController, animated: true, completion: nil)
    }

    func showMoreAlert(forItem invoiceItem: InvoiceItem) {

        // Generic Action Handler

        // Alert Controller

        // Actions

        // Present Alert

    }
    */
}

// MARK: - TableViewDataSourceDelegate Extension
extension InvoiceItemViewController: TableViewDataSourceDelegate {

    func canEdit(_ item: InvoiceItem) -> Bool {
        return true
        //switch item.status {
        //case InvoiceItemStatus.received.rawValue:
        //    return false
        //default:
        //    return true
        //}
    }

    func configure(_ cell: SubItemTableViewCell, for invoiceItem: InvoiceItem) {
        let viewModel = InvoiceItemCellViewModel(forInvoiceItem: invoiceItem)
        cell.configure(withViewModel: viewModel)
    }

}
