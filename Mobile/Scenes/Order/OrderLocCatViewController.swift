//
//  OrderLocCatViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class OrderLocCatViewController: UIViewController {

    private enum Strings {
        static let navTitle = "NAME"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var viewModel: OrderLocCatViewModel!
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()
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
        viewModel.categories
            // closure args are row (IndexPath), element, cell
            .bind(to: tableView.rx.items(cellIdentifier: cellIdentifier)) { _, element, cell in
                cell.textLabel?.text = element.name
            }
            .disposed(by: disposeBag)
    }

}
