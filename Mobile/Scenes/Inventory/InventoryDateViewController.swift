//
//  InventoryDateViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import PKHUD
import RxCocoa
import RxSwift

class InventoryDateViewController: UIViewController, RootSectionViewController {

    // OLD
    var managedObjectContext: NSManagedObjectContext!
    var userManager: CurrentUserManager!

    // MARK: - Properties

    var viewModel: InventoryDateViewModel!
    let disposeBag = DisposeBag()

    let selectedObjects = PublishSubject<Inventory>()

    // TableViewCell
    let cellIdentifier = "InventoryDateTableViewCell"

    // MARK: - Interface
    private let refreshControl = UIRefreshControl()
    let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    let activityIndicatorView = UIActivityIndicatorView()

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
        title = "Inventories"
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.navigationItem.rightBarButtonItem = addButtonItem

        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        //messageLabel.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(tableView)
        self.view.addSubview(activityIndicatorView)
        self.view.addSubview(messageLabel)
    }

    private func setupConstraints() {
        //let marginGuide = view.layoutMarginsGuide

        // TableView
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        // ActivityIndicator
        activityIndicatorView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true

        // MessageLabel
        messageLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
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
        selectedObjects.asObservable()
            .bind(to: viewModel.rowTaps)
            .disposed(by: disposeBag)

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

        /// TEST:
        viewModel.showInventory
            .subscribe(onNext: { [weak self] inventory in
                log.debug("\(#function) SELECTED: \(inventory)")
                switch inventory.uploaded {
                case true:
                    log.info("GET selectedInventory from server - \(inventory.remoteID) ...")
                    //let viewModel = InventoryLocationCategoryViewModel(dataManager: dataManager)
                    let viewController = InventoryLocationCategoryTVC.initFromStoryboard(name: "Main")
                    //viewController.viewModel = viewModel

                    // OLD
                    viewController.managedObjectContext = self?.managedObjectContext
                    guard let locations = inventory.locations?.allObjects else {
                        fatalError("Unable to get selection")
                    }

                    // Exisitng Inventories should have 1 Location - "Default"
                    guard let defaultLocation = locations[0] as? InventoryLocation else {
                        fatalError("Unable to get Default Location")
                    }
                    if defaultLocation.name != "Default" {
                        fatalError("Unable to get Default Location")
                    }
                    viewController.location = defaultLocation
                    viewController.managedObjectContext = self?.managedObjectContext
                    self?.navigationController?.pushViewController(viewController, animated: true)

                case false:
                    log.info("LOAD NEW selectedInventory from disk ...")
                    //let viewModel = InventoryLocationViewModel(dataManager: dataManager)
                    let viewController = InventoryLocationTVC.initFromStoryboard(name: "Main")
                    //viewController.viewModel = viewModel

                    // OLD
                    viewController.managedObjectContext = self?.managedObjectContext
                    viewController.inventory = inventory
                    self?.navigationController?.pushViewController(viewController, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryDateViewController>!

    fileprivate func setupTableView() {
        tableView.refreshControl = refreshControl
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
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
        cell.textLabel?.text = Date(timeIntervalSinceReferenceDate: inventory.date).altStringFromDate()
        switch inventory.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        }
    }

}
