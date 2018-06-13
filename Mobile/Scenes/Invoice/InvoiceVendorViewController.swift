//
//  InvoiceVendorViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class InvoiceVendorViewController: UIViewController {

    private enum Strings {
        static let navTitle = "Vendors"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var bindings: InvoiceVendorViewModel.Bindings {
        return InvoiceVendorViewModel.Bindings(rowTaps: tableView.rx.itemSelected.asDriver())
    }

    var viewModel: InvoiceVendorViewModel!
    let disposeBag = DisposeBag()
    let wasPopped: Observable<Void>
    private let wasPoppedSubject = PublishSubject<Void>()

    // MARK: - Interface

    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.delegate = self
        return tv
    }()

    // MARK: - Lifecycle

    init() {
        self.wasPopped = wasPoppedSubject.asObservable()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        self.wasPopped = wasPoppedSubject.asObservable()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    deinit {
        log.debug("\(#function)")
    }

    // MARK: - View Methods

    private func setupView() {
        title = Strings.navTitle
        self.view.addSubview(tableView)
    }

    private func setupConstraints() {
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    //private func setupBindings() {}

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceVendorViewController>!

    fileprivate func setupTableView() {
        tableView.register(cellType: UITableViewCell.self)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView()
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - UITableViewDelegate
extension InvoiceVendorViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate
extension InvoiceVendorViewController: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for invoice: Invoice) {
        cell.textLabel?.text = invoice.vendor?.name
        switch invoice.status {
        case InvoiceStatus.pending.rawValue:
            cell.textLabel?.textColor = ColorPalette.yellow
        case InvoiceStatus.completed.rawValue:
            cell.textLabel?.textColor = UIColor.black
        case InvoiceStatus.rejected.rawValue:
            /// TODO: what color should we use?
            cell.textLabel?.textColor = ColorPalette.red
            //cell.textLabel?.textColor = UIColor.black
        default:
            log.warning("\(#function) : invalid status for \(invoice)")
            cell.textLabel?.textColor = UIColor.lightGray
        }
    }

}

// MARK: - PoppedObservable
extension InvoiceVendorViewController: PoppedObservable {
    func viewWasPopped() {
        wasPoppedSubject.onNext(())
    }
}
