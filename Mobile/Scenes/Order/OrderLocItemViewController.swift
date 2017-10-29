//
//  OrderLocItemViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/26/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class OrderLocItemViewController: UIViewController {

    private enum Strings {
        static let navTitle = "NAME"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var viewModel: OrderLocItemViewModel!
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
        title = viewModel.navTitle
        //self.navigationItem.leftBarButtonItem =
        //self.navigationItem.rightBarButtonItem =
        tableView.register(SubItemTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
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

        // Errors
        viewModel.errorMessages
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)
        */

        viewModel.items
            .bind(to: tableView.rx.items(cellIdentifier: "Cell", cellType: SubItemTableViewCell.self)) { (_, element, cell: SubItemTableViewCell) in
                // closure args are index (row), model, cell
                guard let cellViewModel = OrderItemCellViewModel(forOrderItem: element) else {
                    fatalError("\(#function) FAILED : unable to init view model")
                }
                cell.configure(withViewModel: cellViewModel)

                //cell.nameTextLabel.text = element.item?.name ?? "Error"
                //cell.textLabel?.text = element.item?.name ?? "Error"
                //cell.nameTextLabel?.text = element.item?.name ?? "Error"
                //cell.configure(forOrderItem: element)
            }
            .disposed(by: disposeBag)

        // Navigation
        tableView.rx
            .modelSelected(OrderItem.self)
            .subscribe(onNext: { item in
                log.debug("We selected: \(item)")
            })
            .disposed(by: disposeBag)
    }

}

// MARK: - TableViewDelegate
extension OrderLocItemViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        rowTaps.onNext(indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
