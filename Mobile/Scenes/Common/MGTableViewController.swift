//
//  MGTableViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/12/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit
import RxSwift

// TODO: should this inhereit from MGViewController; should I define a basic protocol for my VCs?
class MGTableViewController: UIViewController {

    // MARK: - Properties

    let wasPopped: Observable<Void>

    let disposeBag = DisposeBag()
    private let wasPoppedSubject = PublishSubject<Void>()

    // MARK: UI

    // TODO: omit refreshControl?
    let refreshControl = UIRefreshControl()
    /*
    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        return control
    }()
    */
    lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.activityIndicatorViewStyle = .gray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.tableFooterView = UIView() // Prevent empty rows
        tv.translatesAutoresizingMaskIntoConstraints = false
        //tv.delegate = nil
        //tv.dataSource = nil
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

    //deinit { log.debug("\(#function)") }

    // MARK: - View Methods

    func setupView() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        view.addSubview(activityIndicatorView)
        view.addSubview(messageLabel)
        // TODO: set messageLabel.text?

        // Uncomment the following line to preserve selection between presentations.
        // self.clearsSelectionOnViewWillAppear = false

        setupConstraints()
        setupTableView()
        setupBindings()
    }

    func setupConstraints() {
        let guide: UILayoutGuide
        if #available(iOS 11, *) {
            guide = view.safeAreaLayoutGuide
        } else {
            guide = view.layoutMarginsGuide
        }
        let constraints = [
            // TableView
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            // ActivityIndicator
            activityIndicatorView.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
            // MessageLabel
            messageLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12.0),
            messageLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12.0),
            messageLabel.topAnchor.constraint(equalTo: activityIndicatorView.bottomAnchor, constant: 8.0)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func setupBindings() {
        // ...
    }

    func setupTableView() {
        // ...
        //tableView.refreshControl = refreshControl
        //tableView.delegate = self
        //tableView.dataSource = self
        //tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseID)
        //dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - ErrorAlertDisplayable
extension MGTableViewController: ErrorAlertDisplayable {}

// MARK: - PoppedObservable
extension MGTableViewController: PoppedObservable {

    func viewWasPopped() {
        wasPoppedSubject.onNext(())
    }

}
