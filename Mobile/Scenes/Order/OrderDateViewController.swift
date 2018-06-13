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

    // MARK: Alert

    private enum GenerationMethod: CustomStringConvertible {
        //case count(method: NewOrderGenerationMethod)
        //case par(method: NewOrderGenerationMethod)
        case count
        case par
        //case sales
        case cancel

        var description: String {
            switch self {
            case .count:
                return "From Count"
            case .par:
                return "From Par"
            case .cancel:
                return "Cancel"
            }
        }
    }

    // MARK: - Properties

    var viewModel: OrderDateViewModel!
    let disposeBag = DisposeBag()

    let selectedObjects = PublishSubject<OrderCollection>()

    /// TODO: provide interface to control these
    let orderTypeID = 1

    // MARK: - Interface
    private let refreshControl = UIRefreshControl()
    let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
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
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        setupView()
        setupConstraints()
        setupBindings()
        setupTableView()
        /*
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : unable to get storeID"); return
        }

        HUD.show(.progress)
        APIManager.sharedInstance.getListOfOrderCollections(storeID: storeID,
                                                            completion: self.completedGetListOfOrderCollections)
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
        self.navigationItem.rightBarButtonItem = addButtonItem

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

        // Add Button
        addButtonItem.rx.tap
            .flatMap { [weak self] _ -> Observable<GenerationMethod> in
                guard let `self` = self else { return Observable.just(.cancel) }
                let actions: [GenerationMethod] = [.count, .par]
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
        selectedObjects.onNext(dataSource.objectAtIndexPath(indexPath))
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
