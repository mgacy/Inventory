//
//  OrderLocationViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class OrderLocationViewController: UIViewController {

    private enum Strings {
        static let navTitle = "Locations"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var viewModel: OrderLocationViewModel!
    let disposeBag = DisposeBag()

    // TableViewCell
    let cellIdentifier = "Cell"

    // MARK: - Interface

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!

    private let refreshControl = UIRefreshControl()
    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
        setupBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        title = Strings.navTitle
        //self.navigationItem.leftBarButtonItem =
        //self.navigationItem.rightBarButtonItem =
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        self.view.addSubview(tableView)
    }

    private func setupConstraints() {
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    // swiftlint:disable:next function_body_length
    private func setupBindings() {
        /*
        // Refresh
        refreshControl.rx.controlEvent(.valueChanged)
            .bind(to: viewModel.refresh)
            .disposed(by: disposeBag)
         */
        // Activity Indicator
        viewModel.isRefreshing
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        viewModel.isRefreshing
            .map { !$0 }
            .drive(activityIndicatorView.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.isRefreshing
            .map { !$0 }
            .drive(messageLabel.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.showTable
            .map { !$0 }
            .drive(tableView.rx.isHidden)
            .disposed(by: disposeBag)

        // Errors
        viewModel.errorMessages
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)

        // Basic RxCocoa
        viewModel.locations
            // closure args are row (IndexPath), element, cell
            .bind(to: tableView.rx.items(cellIdentifier: cellIdentifier)) { _, element, cell in
                cell.textLabel?.text = element.name
            }
            .disposed(by: disposeBag)

        // Navigation
        tableView.rx
            .modelSelected(RemoteLocation.self)
            .subscribe(onNext: { [weak self] location in
                //log.debug("We selected: \(location)")
                guard let strongSelf = self else { fatalError("\(#function) FAILED : unable to get self") }

                switch location.locationType {
                case .category:
                    guard let controller = OrderLocCatViewController.instance() else {
                        fatalError("\(#function) FAILED : unable to get view controller")
                    }
                    controller.viewModel = OrderLocCatViewModel(dataManager: strongSelf.viewModel.dataManager,
                                                                location: location,
                                                                factory: strongSelf.viewModel.factory)
                    strongSelf.navigationController?.pushViewController(controller, animated: true)
                case .item:
                    guard let controller = OrderLocItemViewController.instance() else {
                        fatalError("\(#function) FAILED : unable to get view controller")
                    }
                    controller.viewModel = OrderLocItemViewModel(dataManager: strongSelf.viewModel.dataManager,
                                                                 parent: OrderLocItemParent.location(location),
                                                                 factory: strongSelf.viewModel.factory)
                    strongSelf.navigationController?.pushViewController(controller, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }

}
