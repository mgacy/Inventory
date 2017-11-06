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
