//
//  MGTableViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/12/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit
import RxSwift

/// TODO: should this inhereit from MGViewController; should I define a basic protocol for my VCs?
class MGTableViewController: UIViewController {

    // MARK: - Properties

    let wasPopped: Observable<Void>

    private let disposeBag = DisposeBag()
    private let wasPoppedSubject = PublishSubject<Void>()

    // MARK: UI

    private let refreshControl = UIRefreshControl()
    private let activityIndicatorView = UIActivityIndicatorView()

    /*
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        return control
    }()

    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
     */
    private lazy var messageLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.tableFooterView = UIView() // Prevent empty rows
        //
        //tv.delegate = self
        //tv.dataSource = ?
        /// TODO: handle everything from setupTableView() here?
        return tv
    }()

    // MARK: - Lifecycle

    init() {
        wasPopped = wasPoppedSubject.asObservable()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    //override func viewWillAppear(_ animated: Bool) {}

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        // ...
        view.addSubview(activityIndicatorView)
        view.addSubview(messageLabel)
        view.addSubview(tableView)

        setupConstraints()
        //setupBindings()
        //setupTableView()
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
        // ...
    }

    func setupTableView() {
        //tableView.delegate = self
        //tableView.dataSource = self

        //tableView.tableFooterView = UIView() // Prevent empty rows
        //tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseID)
    }

    // MARK: - C

}
