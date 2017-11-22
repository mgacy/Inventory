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

    var viewModel: InvoiceVendorViewModel!
    let disposeBag = DisposeBag()
    //let selectedObjects = PublishSubject<IndexPath>()

    // TableViewCell
    let cellIdentifier = "Cell"

    // MARK: - Interface

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
        self.view.addSubview(tableView)
    }

    private func setupConstraints() {
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    //private func setupBindings() {}

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceVendorViewController>!

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }

    // MARK: - Navigation

    fileprivate func showInvoice(withInvoice invoice: Invoice) {
        let vc = InvoiceItemViewController.initFromStoryboard(name: "InvoiceItemViewController")
        vc.viewModel = InvoiceItemViewModel(dataManager: viewModel.dataManager, parentObject: invoice,
                                            uploadTaps: vc.uploadButtonItem.rx.tap.asObservable())
        navigationController?.pushViewController(vc, animated: true)
    }

}

// MARK: - UITableViewDelegate
extension InvoiceVendorViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedObject = dataSource.objectAtIndexPath(indexPath)
        log.verbose("Selected Invoice: \(selectedObject)")
        showInvoice(withInvoice: selectedObject)
        //selectedObjects.onNext(selectedObject)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InvoiceVendorViewController: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for invoice: Invoice) {
       cell.textLabel?.text = invoice.vendor?.name
        switch invoice.status {
        case InvoiceStatus.pending.rawValue:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        case InvoiceStatus.completed.rawValue:
            cell.textLabel?.textColor = UIColor.black
        case InvoiceStatus.rejected.rawValue:
            /// TODO: what color should we use?
            cell.textLabel?.textColor = ColorPalette.redColor
            //cell.textLabel?.textColor = UIColor.black
        default:
            log.warning("\(#function) : invalid status for \(invoice)")
            cell.textLabel?.textColor = UIColor.lightGray
        }
    }

}
