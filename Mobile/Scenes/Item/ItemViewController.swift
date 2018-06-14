//
//  ItemViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/7/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ItemViewController: UIViewController {

    private enum Strings {
        static let navTitle = "Items"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var viewModel: ItemViewModel!
    let disposeBag = DisposeBag()

    // MARK: - Interface
    private let refreshControl = UIRefreshControl()
    @IBOutlet weak var tableView: UITableView!
    /*
    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.delegate = self
        return tv
    }()
    */
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        //setupConstraints()
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
        title = Strings.navTitle
        //self.navigationItem.leftBarButtonItem =
        //self.navigationItem.rightBarButtonItem =

        //self.view.addSubview(tableView)
    }
    /*
    private func setupConstraints() {
        let constraints = [
            // TableView
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    */
    private func setupBindings() {

        // Refresh
        refreshControl.rx.controlEvent(.valueChanged)
            .bind(to: viewModel.refresh)
            .disposed(by: disposeBag)

        // Activity Indicator
        viewModel.isRefreshing
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        viewModel.hasRefreshed
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        /*
        // Errors
        viewModel.errorMessages
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)
        */
        // Navigation
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<ItemViewController>!

    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        tableView.register(cellType: SubItemTableViewCell.self)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView()
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - TableViewDelegate
extension ItemViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension ItemViewController: TableViewDataSourceDelegate {
    /*
    func canEdit(_ model: IndexPath) -> Bool {
        return true
    }
     */
    func configure(_ cell: SubItemTableViewCell, for item: Item) {
        let viewModel = ItemCellViewModel(forItem: item)
        cell.configure(withViewModel: viewModel)
    }

}
