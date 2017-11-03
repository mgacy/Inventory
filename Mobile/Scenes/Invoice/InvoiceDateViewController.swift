//
//  InvoiceDateViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import PKHUD
import RxCocoa
import RxSwift

class InvoiceDateViewController: UIViewController {

    private enum Strings {
        static let navTitle = "Invoices"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    //var viewModel: InvoiceDateViewModelType!
    var viewModel: InvoiceDateViewModel!
    let disposeBag = DisposeBag()

    let selectedObjects = PublishSubject<InvoiceCollection>()

    // TableViewCell
    let cellIdentifier = "Cell"

    // MARK: - Interface
    private let refreshControl = UIRefreshControl()
    //let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    let activityIndicatorView = UIActivityIndicatorView()
    let messageLabel = UILabel()
    //lazy var messageLabel: UILabel = {
    //    let view = UILabel()
    //    view.translatesAutoresizingMaskIntoConstraints = false
    //    return view
    //}()

    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.delegate = self
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
        setupBindings()
        setupTableView()
        /*
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED: unable to get storeID"); return
        }

        HUD.show(.progress)
        APIManager.sharedInstance.getListOfInvoiceCollections(storeID: storeID,
                                                              completion: self.completedGetListOfInvoiceCollections)
         */
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        title = Strings.navTitle
        //self.navigationItem.leftBarButtonItem = self.editButtonItem
        //self.navigationItem.rightBarButtonItem = addButtonItem

        //activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        //messageLabel.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(tableView)
        self.view.addSubview(activityIndicatorView)
        self.view.addSubview(messageLabel)
    }

    private func setupConstraints() {
        // TableView
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        // ActivityIndicator
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true

        // MessageLabel
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
    }

    private func setupBindings() {

        // Edit Button
        //editButtonItem.rx.tap
        //    .bind(to: viewModel.editTaps)
        //    .disposed(by: disposeBag)

        // Row selection
        //selectedObjects.asObservable()
        //    .bind(to: viewModel.rowTaps)
        //    .disposed(by: disposeBag)

        // Refresh
        refreshControl.rx.controlEvent(.valueChanged)
            .bind(to: viewModel.refresh)
            .disposed(by: disposeBag)

        // Activity Indicator
        viewModel.isRefreshing
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        viewModel.hasRefreshed
            /// TODO: use weak or unowned self?
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)

        // Errors
        viewModel.errorMessages
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)

        // Navigation
        viewModel.showCollection
            .subscribe(onNext: { [weak self] selection in
                guard let strongSelf = self else {
                    log.error("\(#function) FAILED : unable to get reference to self"); return
                }
                log.debug("\(#function) SELECTED: \(selection)")

                let vc = InvoiceVendorViewController.initFromStoryboard(name: "InvoiceVendorViewController")
                let vm = InvoiceVendorViewModel(dataManager: strongSelf.viewModel.dataManager, parentObject: selection)
                vc.viewModel = vm
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceDateViewController>!

    fileprivate func setupTableView() {
        tableView.refreshControl = refreshControl
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }
    /*
    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCollection = dataSource.objectAtIndexPath(indexPath)
        guard let selection = selectedCollection else { fatalError("Unable to get selection") }
        guard let storeID = userManager.storeID else {
                log.error("\(#function) FAILED : unable to get storeID"); return
        }
        /*
        HUD.show(.progress)
        log.info("GET InvoiceCollection from server ...")
        APIManager.sharedInstance.getInvoiceCollection(
            storeID: storeID, invoiceDate: selection.date.shortDate,
            completion: completedGetInvoiceCollection)
         */
        /// TODO: move before call to APIManager?
        tableView.deselectRow(at: indexPath, animated: true)
    }
     */
}

// MARK: - TableViewDelegate
extension InvoiceDateViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObjects.onNext(dataSource.objectAtIndexPath(indexPath))
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InvoiceDateViewController: TableViewDataSourceDelegate {
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
    func configure(_ cell: UITableViewCell, for collection: InvoiceCollection) {
        cell.textLabel?.text = collection.date.altStringFromDate()
        switch collection.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        }
    }

}
/*
// MARK: - Completion Handlers + Sync
extension InvoiceDateViewController {

    // MARK: Completion Handlers

    func completedGetListOfInvoiceCollections(json: JSON?, error: Error?) {
        refreshControl?.endRefreshing()
        guard error == nil else {
            //if error?._code == NSURLErrorTimedOut {}
            log.error("\(#function) FAILED : \(String(describing: error))")
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.warning("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }

        do {
            try managedObjectContext.syncCollections(InvoiceCollection.self, withJSON: json)
            //try InvoiceCollection.sync(withJSON: json, in: managedObjectContext)
        } catch let error {
            log.error("Unable to sync Invoices: \(error)")
            HUD.flash(.error, delay: 1.0)
        }
        HUD.hide()
        managedObjectContext.performSaveOrRollback()
        tableView.reloadData()
    }

    func completedGetInvoiceCollection(json: JSON?, error: Error?) {
        guard error == nil else {
            log.error("Unable to get InvoiceCollection: \(String(describing: error))")
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }
        guard let selection = selectedCollection else {
            log.error("\(#function) FAILED : still unable to get selected InvoiceCollection"); return
        }

        /// TODO: make this more elegant
        var jsonArray: [JSON] = []
        for (_, objectJSON) in json {
            jsonArray.append(objectJSON)
        }

        // Update selected Inventory with full JSON from server.
        selection.syncChildren(in: managedObjectContext!, with: jsonArray)
        managedObjectContext!.performSaveOrRollback()

        HUD.hide()
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedSync(_ succeeded: Bool, error: Error?) {
        if succeeded {
            log.verbose("Completed login / sync - succeeded: \(succeeded)")
            guard let storeID = userManager.storeID else {
                log.error("\(#function) FAILED : unable to get storeID")
                HUD.flash(.error, delay: 1.0); return
            }

            // Get list of Invoices from server
            log.verbose("Fetching existing InvoiceCollections from server ...")
            APIManager.sharedInstance.getListOfInvoiceCollections(storeID: storeID,
                                                                  completion: self.completedGetListOfInvoiceCollections)
        } else {
            // if let error = error { // present more detailed error ...
            log.error("Unable to sync: \(String(describing: error))")
            refreshControl?.endRefreshing()
            HUD.flash(.error, delay: 1.0)
        }
    }

}
*/
