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
    /*
    var bindings: OrderLocationViewModel.Bindings {
        return OrderLocationViewModel.Bindings(
            //cancelTaps: cancelButtonItem.rx.tap.asObservable(),
            //rowTaps: tableView.rx.itemSelected.asDriver()
            rowTaps: tableView.rx.itemSelected.asObservable()
            //uploadTaps: uploadButtonItem.rx.tap.asObservable()
        )
    }
    */
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

        /// TODO: there is an ActivityIndicator property we can set so it automatically hides when stopped
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
    }

}
