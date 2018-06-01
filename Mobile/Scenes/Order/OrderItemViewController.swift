//
//  OrderItemViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import MessageUI
import PKHUD
import RxCocoa
import RxSwift

class OrderItemViewController: UIViewController {

    // MARK: - Properties

    var bindings: OrderViewModel.Bindings {
        return OrderViewModel.Bindings(
            rowTaps: tableView.rx.itemSelected.asObservable(),
            placedOrder: placedOrder.asObservable()
        )
    }

    var viewModel: OrderViewModel!
    let disposeBag = DisposeBag()

    let placedOrder = PublishSubject<Void>()

    // Create a MessageComposer
    /// TODO: should I instantiate this here or only in `.setupView()`?
    // var mailComposer: MailComposer? = nil
    let messageComposer = MessageComposer()

    // TableView
    let cellIdentifier = "OrderItemCell"

    // MARK: - Views

    lazy var headerView: OrderItemHeaderView = {
        let view = OrderItemHeaderView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.delegate = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    //lazy var footerView: OrderItemFooterView = {
    //    let view = OrderItemFooterView()
    //    view.backgroundColor = .white
    //    view.translatesAutoresizingMaskIntoConstraints = false
    //    return view
    //}()

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //title = viewModel.vendorName
        //setupBindings()
        //setupTableView()
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        // Update in case we have returned from the keypad where we updated the quantity of an OrderItem
        viewModel.updateOrderStatus()
        //setupView()
    }

    // MARK: - View Methods

    private func setupView() {
        title = viewModel.vendorName

        view.addSubview(headerView)
        view.addSubview(tableView)
        //view.addSubview(footerView)

        setupConstraints()
        setupBindings()

        // Subviews
        setupTableView()
        //setupTableView(with: viewModel)
        setupHeaderView()
        //setupFooterView()
    }

    private func setupHeaderView() {
        headerView.repNameTextLabel.text = viewModel.repName

        headerView.messageButton.addTarget(self, action: #selector(tappedMessageButton(_:)), for: .touchDown)
        headerView.emailButton.addTarget(self, action: #selector(tappedEmailButton(_:)), for: .touchDown)
        headerView.callButton.addTarget(self, action: #selector(tappedCallButton(_:)), for: .touchDown)

        #if !(arch(i386) || arch(x86_64)) && os(iOS)
            guard messageComposer.canSendText() else {
                headerView.messageButton.isEnabled = false
                return
            }
        #endif

        /// TODO: handle orders that have been placed but not uploaded; display different `upload` button
        headerView.messageButton.isEnabled = viewModel.canMessageOrder
    }

    //private func setupFooterView() {}

    private func setupConstraints() {
        let guide: UILayoutGuide
        if #available(iOS 11, *) {
            guide = view.safeAreaLayoutGuide
        } else {
            guide = view.layoutMarginsGuide
        }
        let constraints = [
            // headerView
            headerView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            headerView.topAnchor.constraint(equalTo: guide.topAnchor),
            headerView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 120.0),
            // footerView
            //footerView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            //footerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            //footerView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            //footerView.heightAnchor.constraint(equalToConstant: 50.0),
            // tableView
            tableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            //tableView.bottomAnchor.constraint(equalTo: footerView.topAnchor)
            tableView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func setupBindings() {

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
                        self?.navigationController!.popViewController(animated: true)
                    }
                case .error(let error):
                    log.error("\(#function) FAILED : \(String(describing: error))")
                    HUD.flash(.error, delay: 1.0)
                    //UIViewController.showErrorInHUD(title: "Strings.errorAlertTitle", subtitle: "Message")
                    //showAlert(title: "Problem", message: "Unable to upload Order")

                case .completed:
                    log.warning("\(#function) : not sure how to handle completion")
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<OrderItemViewController>!

    /// TODO: pass `(with viewModel: OrderItemViewModel)`?
    fileprivate func setupTableView() {
        tableView.register(SubItemTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 80
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }

    // MARK: - User Actions

    @objc func tappedMessageButton(_ sender: UIButton) {
        log.debug("Send message ...")

        // Simply POST the order if we already sent the message but were unable to POST it previously

        guard let message = viewModel.orderMessage else {
            log.error("\(#function) FAILED : unable to getOrderMessage"); return
        }

        #if !(arch(i386) || arch(x86_64)) && os(iOS)
            /// TODO: wait until this point to instantiate `MessageComposer`?
            let messageComposeVC = messageComposer.configuredMessageComposeViewController(
                phoneNumber: viewModel.phone, message: message,
                completionHandler: completedPlaceOrder)
            present(messageComposeVC, animated: true, completion: nil)
        #else
            completedPlaceOrder(.sent)
        #endif

    }

    @objc func tappedEmailButton(_ sender: UIButton) {
        log.debug("Email message ...")
    }

    @objc func tappedCallButton(_ sender: UIButton) {
        log.debug("Call representative ...")
    }

}

// MARK: - Completion Handlers
extension OrderItemViewController {

    func completedPlaceOrder(_ result: MessageComposeResult) {
        switch result {
        case .cancelled:
            log.info("Message was cancelled")
        case .failed:
            log.error("\(#function) FAILED : unable to send Order message")
            showAlert(title: "Problem", message: "Unable to send Order message")
        case .sent:
            log.info("Sent Order message")
            placedOrder.onNext(())
        }
    }

}

// MARK: - UITableViewDelegate Extension
extension OrderItemViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        //let orderItem = dataSource.objectAtIndexPath(indexPath)

        // Set to 0
        let setToZero = UITableViewRowAction(style: .normal, title: "No Order") { [weak self] _, _ in
            guard let strongSelf = self else {
                log.error("\(#function) FAILED : unable to get self"); return
            }
            strongSelf.viewModel.setOrderToZero(forItemAtIndexPath: indexPath)
            tableView.isEditing = false
            // ALT
            // https://stackoverflow.com/a/43626096/4472195
            //self.tableView.cellForRow(at: cellIndex)?.setEditing(false, animated: true)
            //self.tableView.reloadData() // this is necessary, otherwise, it won't animate
        }
        setToZero.backgroundColor = ColorPalette.lightGray

        return [setToZero]
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension OrderItemViewController: TableViewDataSourceDelegate {

    func canEdit(_ item: OrderItem) -> Bool {
        guard viewModel.rawOrderStatus == OrderStatus.pending.rawValue else {
            return false
        }
        guard let quantity = item.quantity else {
            return false
        }
        if quantity.doubleValue > 0.0 {
            return true
        } else {
            return false
        }
    }

    func configure(_ cell: SubItemTableViewCell, for orderItem: OrderItem) {
        /// TODO: simply add extension on SubItemTableViewCell passing OrderItem as arg?
        //cell.configure(forOrderItem: orderItem)
        let viewModel = OrderItemCellViewModel(forOrderItem: orderItem)!
        cell.configure(withViewModel: viewModel)
    }

}
