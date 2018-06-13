//
//  InvoiceItemTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import PKHUD
import RxCocoa
import RxSwift

class InvoiceItemViewController: UIViewController {

    private enum Strings {
        //static let navTitle
        static let errorAlertTitle = "Error"
        // Actions
        static let alertMessage = "Why wasn't this item received?"
        //static let notReceivedActionTitle = "Not Received ..."
        //static let moreActionTitle = "More"
        //static let receivedActionTitle = "Received"
        //static let damagedActionTitle = "Damaged"
        //static let outOfStockActionTitle = "Out of Stock"
        //static let wrongItemActionTitle = "Wrong Item"
        //static let cancelActionTitle = "Cancel"
    }

    // MARK: - Properties

    var viewModel: InvoiceItemViewModel!
    let disposeBag = DisposeBag()

    /// TODO: make PublishSubject fileprivate and expose observable
    let selectedIndices = PublishSubject<IndexPath>()

    // TableView
    var cellIdentifier = "InvoiceItemCell"

    // MARK: - Interface
    let uploadButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Upload"), style: UIBarButtonItemStyle.plain, target: nil, action: nil)

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

    func setupView() {
        title = viewModel.vendorName
        self.navigationItem.rightBarButtonItem = uploadButtonItem
        self.view.addSubview(tableView)
    }

    private func setupConstraints() {
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    func setupBindings() {

        // Uploading
        viewModel.isUploading
            .filter { $0 }
            .drive(onNext: { _ in
                HUD.show(.progress)
            })
            .disposed(by: disposeBag)

        viewModel.uploadResults
            .subscribe(onNext: { [weak self] result in
                switch result.event {
                case .next:
                    HUD.flash(.success, delay: 0.5) { _ in
                        /// TODO: handle this elsewhere
                        self?.navigationController!.popViewController(animated: true)
                    }
                case .error:
                    /// TODO: `case.error(let error):; switch error {}`
                    UIViewController.showErrorInHUD(title: Strings.errorAlertTitle, subtitle: "Message")
                case .completed:
                    log.warning("\(#function) : not sure how to handle completion")
                }
            })
            .disposed(by: disposeBag)

        // Errors
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceItemViewController>!

    fileprivate func setupTableView() {
        tableView.register(SubItemTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - UITableViewDelegate
extension InvoiceItemViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndices.onNext(indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        // More
        let more = UITableViewRowAction(style: .normal, title: "More") { _, indexPath in
            /// TODO: .promo and .substitute will require further action
            let statusList: [InvoiceItemStatus] = [.damaged, .wrongItem, .notReceived]
            self.showNotReceivedAlert(forItemAt: indexPath, with: statusList,
                                      handler: self.viewModel.updateItemStatus(forItemAt:withStatus:))
        }
        more.backgroundColor = UIColor.lightGray
        //more.backgroundColor = ColorPalette.yellowColor

        // Out of Stock
        let outOfStock = UITableViewRowAction(style: .normal, title: "Out of Stock") { _, indexPath in
            self.viewModel.updateItemStatus(forItemAt: indexPath, withStatus: .outOfStock)
        }
        outOfStock.backgroundColor = ColorPalette.red

        // Received
        let received = UITableViewRowAction(style: .normal, title: "Received") { [weak self] _, indexPath in
            /// TODO: do we not need to handle setting `self.isEditing = false`?
            self?.viewModel.updateItemStatus(forItemAt: indexPath, withStatus: .received) //{ self?.isEditing = false }
        }
        received.backgroundColor = ColorPalette.navy

        return [received, outOfStock, more]
    }

}

// MARK: - Alert Controller
extension InvoiceItemViewController {

    func showNotReceivedAlert(forItemAt indexPath: IndexPath, with statusList: [InvoiceItemStatus], handler: @escaping (IndexPath, InvoiceItemStatus) -> Void) {

        // Alert Controller
        let alertController = UIAlertController(title: nil, message: Strings.alertMessage,
                                                preferredStyle: .adaptiveActionSheet)

        statusList.forEach { status in
            alertController.addAction(UIAlertAction(title: status.description, style: .default) { _ in
                handler(indexPath, status)
            })
        }

        // cancel
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            self.isEditing = false
        }))

        // Present Alert
        present(alertController, animated: true, completion: nil)
    }

}

// MARK: - TableViewDataSourceDelegate
extension InvoiceItemViewController: TableViewDataSourceDelegate {

    func canEdit(_ item: InvoiceItem) -> Bool {
        return true
        //switch item.status {
        //case InvoiceItemStatus.received.rawValue:
        //    return false
        //default:
        //    return true
        //}
    }

    func configure(_ cell: SubItemTableViewCell, for invoiceItem: InvoiceItem) {
        let viewModel = InvoiceItemCellViewModel(forInvoiceItem: invoiceItem)
        cell.configure(withViewModel: viewModel)
    }

}
