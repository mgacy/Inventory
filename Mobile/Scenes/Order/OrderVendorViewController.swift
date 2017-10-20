//
//  OrderVendorViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import RxCocoa
import RxSwift

class OrderVendorViewController: UIViewController {

    // OLD
    var parentObject: OrderCollection!

    // MARK: - Properties

    var viewModel: OrderVendorViewModel!
    let disposeBag = DisposeBag()

    let refresh = PublishSubject<Void>()
    let selectedObjects = PublishSubject<Order>()
    let confirmComplete = PublishSubject<Void>()

    // TableView
    var cellIdentifier = "Cell"

    // MARK: - Interface

    let completeButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "DoneBarButton"), style: .done, target: nil, action: nil)

    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.delegate = self
        return tv
    }()

    private enum Strings {
        static let navTitle = "Vendors"
        //static let errorAlertTitle = "Error"
        static let confirmCompleteTitle = "Warning: Pending Orders"
        static let confirmCompleteMessage = "Marking order collection as completed will delete any pending " +
        "orders. Are you sure you want to proceed?"
    }

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
        refresh.onNext(())
        //parentObject.updateStatus()
        //self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        title = Strings.navTitle
        navigationItem.rightBarButtonItem = completeButtonItem
        self.view.addSubview(tableView)
    }

    private func setupConstraints() {
        // TableView
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    private func setupBindings() {

        refresh.asObservable()
            .bind(to: viewModel.refresh)
            .disposed(by: disposeBag)

        viewModel.hasRefreshed
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)

        viewModel.showAlert
            .drive(onNext: { [weak self] _ in
                self?.showAlert(title: Strings.confirmCompleteTitle, message: Strings.confirmCompleteMessage) {
                    self?.confirmComplete.onNext(())
                }
            })
            .disposed(by: disposeBag)

        confirmComplete.asObservable()
            .bind(to: viewModel.confirmComplete)
            .disposed(by: disposeBag)

        // Navigation
        viewModel.showNext
            .subscribe(onNext: { [weak self] segue in
                switch segue {
                case .back:
                    self?.navigationController!.popViewController(animated: true)
                case .item(let order):
                    self?.showOrderItemView(withOrder: order)
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Navigation

    private func showOrderItemView(withOrder order: Order) {
        guard let destinationController = OrderItemViewController.instance() else {
            fatalError("\(#function) FAILED: unable to get destination view controller.")
        }
        destinationController.viewModel = OrderViewModel(dataManager: viewModel.dataManager, parentObject: order)
        destinationController.parentObject = order
        destinationController.managedObjectContext = viewModel.dataManager.managedObjectContext
        navigationController?.pushViewController(destinationController, animated: true)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<OrderVendorViewController>!

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - UITableViewDelegate
extension OrderVendorViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObjects.onNext(dataSource.objectAtIndexPath(indexPath))
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate
extension OrderVendorViewController: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for order: Order) {
        cell.textLabel?.text = order.vendor?.name

        /// TODO: handle situation where user placed an order but uploading to the server failed;
        // we still need to make sure that it ends up getting uploaded

        switch order.status {
        case OrderStatus.incomplete.rawValue:
            cell.textLabel?.textColor = ColorPalette.redColor
        case OrderStatus.empty.rawValue:
            cell.textLabel?.textColor = UIColor.lightGray
        case OrderStatus.pending.rawValue:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        case OrderStatus.placed.rawValue:
            /// TODO: use another color?
            cell.textLabel?.textColor = UIColor.black
        case OrderStatus.uploaded.rawValue:
            cell.textLabel?.textColor = UIColor.black
        default:
            /// TODO: use another color for values that aren't captured above
            cell.textLabel?.textColor = UIColor.blue
        }
    }

}
