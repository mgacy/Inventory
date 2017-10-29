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

    let rowTaps = PublishSubject<IndexPath>()

    // TableViewCell
    let cellIdentifier = "Cell"

    // MARK: - Interface
    private let refreshControl = UIRefreshControl()
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
        /*
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
         */
        // Errors
        viewModel.errorMessages
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)

        viewModel.locations
            .subscribe(onNext: { _ in
                //log.debug("\(#function) LOCATIONS: \(locations)")
                log.debug("Got locations")
            })
            .disposed(by: disposeBag)

        // Navigation

    }

}

// MARK: - TableViewDelegate
extension OrderLocationViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //rowTaps.onNext(dataSource.objectAtIndexPath(indexPath))
        rowTaps.onNext(indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
