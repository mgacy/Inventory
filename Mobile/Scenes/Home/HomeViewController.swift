//
//  HomeViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/7/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class HomeViewController: UIViewController {

    private enum Strings {
        /// TODO: navTitle should be store name
        static let navTitle = "Home"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var viewModel: HomeViewModel!
    let disposeBag = DisposeBag()

    // MARK: - Interface
    let settingsButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Settings"), style: .plain, target: nil, action: nil)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        //setupConstraints()
        setupBindings()
        //setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        title = Strings.navTitle
        self.navigationItem.leftBarButtonItem = settingsButtonItem
        //self.navigationItem.rightBarButtonItem =
    }

    //private func setupConstraints() {}

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

        // Errors
        viewModel.errorMessages
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)
         */
        // Navigation
        settingsButtonItem.rx.tap
            .subscribe(onNext: { [weak self] in
                log.debug("Tapped settings button")
                guard let strongSelf = self else { fatalError("\(#function) FAILED : unable to get self") }
                let controller = SettingsViewController.initFromStoryboard(name: "SettingsViewController")
                controller.viewModel = SettingsViewModel(dataManager: strongSelf.viewModel.dataManager,
                                                         rowTaps: controller.rowTaps.asObservable())
                let navigationController = UINavigationController(rootViewController: controller)
                strongSelf.navigationController?.present(navigationController, animated: true, completion: nil)

            })
            .disposed(by: disposeBag)
    }
    /*
    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<HomeViewController>!

    fileprivate func setupTableView() {
        tableView.refreshControl = refreshControl
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }
    */
}
