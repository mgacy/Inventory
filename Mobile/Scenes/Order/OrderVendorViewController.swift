//
//  OrderVendorViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class OrderVendorViewController: UIViewController {

    // MARK: - Properties

    var viewModel: OrderVendorViewModel!
    let disposeBag = DisposeBag()

    let refresh = PublishSubject<Void>()
    let selectedObjects = PublishSubject<Order>()
    let confirmComplete = PublishSubject<Void>()

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

    deinit { log.debug("\(#function)") }

    // MARK: - View Methods

    private func setupView() {
        title = Strings.navTitle
        // TODO: should we show this button as disabled or simply omit it?
        navigationItem.rightBarButtonItem = completeButtonItem
        completeButtonItem.isEnabled = false
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
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<OrderVendorViewController>!

    fileprivate func setupTableView() {
        tableView.register(cellType: UITableViewCell.self)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView()
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
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

        // TODO: handle situation where user placed an order but uploading to the server failed;
        // we still need to make sure that it ends up getting uploaded

        switch order.status {
        case OrderStatus.incomplete.rawValue:
            cell.textLabel?.textColor = ColorPalette.red
        case OrderStatus.empty.rawValue:
            cell.textLabel?.textColor = UIColor.lightGray
        case OrderStatus.pending.rawValue:
            cell.textLabel?.textColor = ColorPalette.yellow
        case OrderStatus.placed.rawValue:
            // TODO: use another color?
            cell.textLabel?.textColor = UIColor.black
        case OrderStatus.uploaded.rawValue:
            cell.textLabel?.textColor = UIColor.black
        default:
            // TODO: use another color for values that aren't captured above
            cell.textLabel?.textColor = UIColor.blue
        }
    }

}
