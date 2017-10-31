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
    /*
    private enum Strings {
        static let navTitle = "NAME"
        static let errorAlertTitle = "Error"
    }
    */
    // MARK: - Properties

    var viewModel: OrderLocItemViewModel!
    let disposeBag = DisposeBag()

    // TableViewCell
    let cellIdentifier = "Cell"

    // MARK: - Interface
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
        title = viewModel.navTitle
        //self.navigationItem.leftBarButtonItem =
        //self.navigationItem.rightBarButtonItem =
        tableView.register(SubItemTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        self.view.addSubview(tableView)
    }

    private func setupConstraints() {
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    private func setupBindings() {
        // TableView
        viewModel.items
            // closure args are index (row), model, cell
            .bind(to: tableView.rx.items(cellIdentifier: "Cell", cellType: SubItemTableViewCell.self)) { (_, element, cell: SubItemTableViewCell) in
                guard let cellViewModel = OrderItemCellViewModel(forOrderItem: element) else {
                    fatalError("\(#function) FAILED : unable to init view model for \(element)")
                }
                cell.configure(withViewModel: cellViewModel)
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
