//
//  OrderDateViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/29/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import PKHUD
import RxCocoa
import RxSwift

class OrderDateViewController: UIViewController {

    private enum Strings {
        static let navTitle = "Orders"
        static let errorAlertTitle = "Error"
        static let newOrderTitle = "Create Order"
        static let newOrderMessage = "Set order quantities from the most recent inventory or simply use pars?"
    }

    // MARK: - Properties

    var bindings: OrderDateViewModel.Bindings {
        /*
        let viewWillAppear = rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        let refresh = refreshControl.rx
            .controlEvent(.valueChanged)
            .asDriver()
        */
        // MARK: Alert
        let addTaps = addButtonItem.rx.tap
            .flatMap { [weak self] _ -> Observable<OrderDateViewModel.GenerationMethod> in
                guard let `self` = self else { return Observable.just(.cancel) }
                let actions: [OrderDateViewModel.GenerationMethod] = [.count, .par]
                return self.promptFor(title: Strings.newOrderTitle, message: Strings.newOrderMessage,
                                      cancelAction: .cancel, actions: actions)
            }
            .filter { $0 != .cancel }
            .map { method -> NewOrderGenerationMethod in
                switch method {
                case .count:
                    return NewOrderGenerationMethod.count
                case .par:
                    return NewOrderGenerationMethod.par
                default:
                    return NewOrderGenerationMethod.par
                }
            }

        return OrderDateViewModel.Bindings(
            //fetchTrigger: Driver.merge(viewWillAppear, refresh),
            fetchTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver(),
            addTaps: addTaps.asDriver(onErrorDriveWith: .empty()),
            //editTaps = editButtonItem.rx.tap.asDriver(),
            rowTaps: tableView.rx.itemSelected.asDriver()
        )
    }
    var viewModel: OrderDateViewModel!
    let disposeBag = DisposeBag()

    // TODO: provide interface to control these
    let orderTypeID = 1

    // MARK: - Interface
    let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
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
        self.navigationItem.rightBarButtonItem = addButtonItem

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

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
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            // MessageLabel
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: activityIndicatorView.bottomAnchor, constant: 5.0)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func setupBindings() {
        // Activity Indicator
        viewModel.isRefreshing
            .delay(0.01)
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
        /*
        viewModel.hasRefreshed
            // TODO: use weak or unowned self?
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        */
        // Errors
        viewModel.errorMessages
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<OrderDateViewController>!

    fileprivate func setupTableView() {
        tableView.refreshControl = refreshControl
        tableView.register(cellType: UITableViewCell.self)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 100

        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - TableViewDelegate
extension OrderDateViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension OrderDateViewController: TableViewDataSourceDelegate {

    func canEdit(_ collection: OrderCollection) -> Bool {
        switch collection.uploaded {
        case true:
            return false
        case false:
            return true
        }
    }

    func configure(_ cell: UITableViewCell, for collection: OrderCollection) {
        cell.textLabel?.text = collection.date.altStringFromDate()

        switch collection.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.yellow
        }
    }

}
