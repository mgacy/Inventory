//
//  InventoryDateViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import PKHUD
import RxCocoa
import RxSwift

class InventoryDateViewController: UIViewController {

    private enum Strings {
        static let navTitle = "Inventories"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var viewModel: InventoryDateViewModel!
    let disposeBag = DisposeBag()

    let selectedObjects = PublishSubject<Inventory>()

    // MARK: - Interface
    //private let refreshControl = UIRefreshControl()
    let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    //let activityIndicatorView = UIActivityIndicatorView()
    //let messageLabel = UILabel()

    lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        return control
    }()

    lazy var messageLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

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
        // Uncomment the following line to preserve selection between presentations.
        // self.clearsSelectionOnViewWillAppear = false
        setupView()
        setupConstraints()
        setupBindings()
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
        //self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.navigationItem.rightBarButtonItem = addButtonItem

        //activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        //messageLabel.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(tableView)
        self.view.addSubview(activityIndicatorView)
        self.view.addSubview(messageLabel)
    }

    private func setupConstraints() {
        //let guide: UILayoutGuide
        //if #available(iOS 11, *) {
        //    guide = view.safeAreaLayoutGuide
        //} else {
        //    guide = view.layoutMarginsGuide
        //}
        let constraints = [
            // TableView
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            // ActivityIndicator
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            // MessageLabel
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: activityIndicatorView.bottomAnchor, constant: 5.0)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func setupBindings() {
        // Add Button
        addButtonItem.rx.tap
            .bind(to: viewModel.addTaps)
            .disposed(by: disposeBag)

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
            //.debug("refreshControl")
            .bind(to: viewModel.refresh)
            .disposed(by: disposeBag)

        // Activity Indicator

        viewModel.isRefreshing
            //.debug("isRefreshing")
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        viewModel.hasRefreshed
            //.debug("hasRefreshed")
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
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryDateViewController>!

    fileprivate func setupTableView() {
        tableView.refreshControl = refreshControl
        tableView.register(cellType: UITableViewCell.self)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView()
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - TableViewDelegate
extension InventoryDateViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObjects.onNext(dataSource.objectAtIndexPath(indexPath))
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InventoryDateViewController: TableViewDataSourceDelegate {

    func canEdit(_ inventory: Inventory) -> Bool {
        switch inventory.uploaded {
        case true:
            return false
        case false:
            return true
        }
    }

    func configure(_ cell: UITableViewCell, for inventory: Inventory) {
        cell.textLabel?.text = Date(timeIntervalSinceReferenceDate: inventory.dateTimeInterval).altStringFromDate()
        switch inventory.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.yellow
        }
    }

}
