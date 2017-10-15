//
//  InventoryReviewViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/11/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
//import CoreData
import PKHUD
import RxCocoa
import RxSwift

class InventoryReviewViewController: UIViewController {

    // MARK: - Properties

    var viewModel: InventoryReviewViewModel!
    let disposeBag = DisposeBag()

    // TODO: could we use a lazy var returning selectedObjects.asObservable()?
    let selectedObjects = PublishSubject<InventoryItem>()

    // TableViewCell
    let cellIdentifier = "Cell"

    // MARK: - Interface
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!
    /*
    let activityIndicatorView = UIActivityIndicatorView()
    //let messageLabel = UILabel()
    lazy var messageLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .red
        return view
    }()
     */
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        title = "Items"
        /// TODO: add `messageLabel` output to viewModel?
        messageLabel.text = "You do not have any Items yet."

        //self.navigationItem.leftBarButtonItem = self.editButtonItem
        //self.navigationItem.rightBarButtonItem = addButtonItem

        //activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        //messageLabel.translatesAutoresizingMaskIntoConstraints = false

        //self.view.addSubview(activityIndicatorView)
        //self.view.addSubview(messageLabel)
        self.view.addSubview(tableView)
    }

    private func setupConstraints() {
        // TableView
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        /*
        // ActivityIndicator
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true

        // MessageLabel
        //messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        messageLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true
         */
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

        // Selection
        viewModel.showSelection
            .subscribe(onNext: { [weak self] selection in
                log.debug("\(#function) SELECTED: \(selection)")
                /*
                guard let strongSelf = self else {
                    log.error("\(#function) FAILED : unable to get reference to self"); return
                }
                 */
                //let viewController = InvoiceVendorViewController.initFromStoryboard(name: "Main")
                //let viewModel = InvoiceVendorViewModel(dataManager: viewModel.dataManager)
                //viewController = viewModel = viewModel
                //strongSelf.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryReviewViewController>!

    fileprivate func setupTableView() {
        //tableView.refreshControl = refreshControl
        tableView.register(SubItemTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - TableViewDelegate
extension InventoryReviewViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObjects.onNext(dataSource.objectAtIndexPath(indexPath))
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
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
