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

    var bindings: InvoiceDateViewModel.Bindings {
        /*
        let viewWillAppear = rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        let refresh = refreshControl.rx
            .controlEvent(.valueChanged)
            .asDriver()
        */
        return InvoiceDateViewModel.Bindings(
            fetchTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver(),
            //fetchTrigger: Driver.merge(viewWillAppear, refresh),
            //addTaps = addButtonItem.rx.tap.asDriver(),
            //editTaps = editButtonItem.rx.tap.asDriver(),
            rowTaps: tableView.rx.itemSelected.asDriver()
        )
    }
    var viewModel: InvoiceDateViewModel!
    let disposeBag = DisposeBag()

    // MARK: - Interface

    //let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    //let editButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)

    lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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

    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        return control
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
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

        self.view.addSubview(tableView)
        self.view.addSubview(activityIndicatorView)
        self.view.addSubview(messageLabel)

        setupConstraints()
        setupBindings()
        setupTableView()
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
            activityIndicatorView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            // MessageLabel
            messageLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func setupBindings() {

        // Activity Indicator
        viewModel.isRefreshing
            //.debug("isRefreshing")
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

//        viewModel.hasRefreshed
//            //.debug("hasRefreshed")
//            .drive(onNext: { [weak self] _ in
//                self?.tableView.reloadData()
//            })
//            .disposed(by: disposeBag)

        // Errors
        viewModel.errorMessages
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceDateViewController>!

    fileprivate func setupTableView() {
        tableView.refreshControl = refreshControl
        tableView.register(cellType: UITableViewCell.self)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView()
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - TableViewDelegate
extension InvoiceDateViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate
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
            cell.textLabel?.textColor = ColorPalette.yellow
        }
    }

}
