//
//  OrderDateViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/29/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import PKHUD
import RxCocoa
import RxSwift

// swiftlint:disable file_length

class OrderDateViewController: UIViewController {

    // OLD
    //var userManager: CurrentUserManager!
    //var selectedCollection: OrderCollection?

    private enum Strings {
        static let navTitle = "Orders"
        static let errorAlertTitle = "Error"
        static let newOrderTitle = "Create Order"
        static let newOrderMessage = "Set order quantities from the most recent inventory or simply use pars?"
    }

    // MARK: - Properties

    var viewModel: OrderDateViewModel!
    let disposeBag = DisposeBag()

    let selectedObjects = PublishSubject<OrderCollection>()

    // TableViewCell
    let cellIdentifier = "Cell"

    /// TODO: provide interface to control these
    let orderTypeID = 1

    // MARK: - Interface
    private let refreshControl = UIRefreshControl()
    let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    let activityIndicatorView = UIActivityIndicatorView()
    let messageLabel = UILabel()
    //lazy var messageLabel: UILabel = {
    //    let view = UILabel()
    //    view.translatesAutoresizingMaskIntoConstraints = false
    //    return view
    //}()

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
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        setupView()
        setupConstraints()
        setupBindings()
        setupTableView()
        /*
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : unable to get storeID"); return
        }

        HUD.show(.progress)
        APIManager.sharedInstance.getListOfOrderCollections(storeID: storeID,
                                                            completion: self.completedGetListOfOrderCollections)
     */
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        title = Strings.navTitle
        //self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.navigationItem.rightBarButtonItem = addButtonItem

        self.view.addSubview(tableView)
        self.view.addSubview(activityIndicatorView)
        self.view.addSubview(messageLabel)
    }

    private func setupConstraints() {
        // TableView
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        // ActivityIndicator
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true

        // MessageLabel
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
    }

    // swiftlint:disable:next function_body_length
    private func setupBindings() {

        // Add Button
        addButtonItem.rx.tap
            .flatMap { [weak self] _ -> Observable<GenerationMethod> in
                guard let `self` = self else { return Observable.just(.cancel) }
                let actions: [GenerationMethod] = [.count, .par]
                return self.promptFor(title: Strings.newOrderTitle, message: Strings.newOrderMessage,
                                      cancelAction: .cancel, actions: actions)
            }
            .filter { $0 != .cancel }
            .map { method -> NewOrderGenerationMethod in
                switch method {
                case .count:
                    return NewOrderGenerationMethod.count
                case .par:
                    return NewOrderGenerationMethod.par
                default:
                    return NewOrderGenerationMethod.par
                }
            }
            .bind(to: viewModel.addTaps)
            .disposed(by: disposeBag)

        // Edit Button
        //editButtonItem.rx.tap
        //    .bind(to: viewModel.editTaps)
        //    .disposed(by: disposeBag)

        // Row selection
        //selectedObjects.asObservable()
        //    .bind(to: viewModel.rowTaps)
        //    .disposed(by: disposeBag)

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

        // Navigation
        viewModel.showCollection
            .subscribe(onNext: { [weak self] selection in
                guard let strongSelf = self else {
                    log.error("\(#function) FAILED : unable to get reference to self"); return
                }
                log.debug("\(#function) SELECTED / CREATED: \(selection)")

                let vc = OrderVendorViewController.initFromStoryboard(name: "OrderVendorViewController")
                let vm = OrderVendorViewModel(dataManager: strongSelf.viewModel.dataManager,
                                              parentObject: selection,
                                              rowTaps: vc.selectedObjects.asObservable(),
                                              completeTaps: vc.completeButtonItem.rx.tap.asObservable()
                )
                vc.viewModel = vm
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<OrderDateViewController>!

    fileprivate func setupTableView() {
        tableView.refreshControl = refreshControl
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100

        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }

    /*
    // MARK: - User Actions

    @IBAction func newTapped(_ sender: AnyObject) {
        /// TODO: check if there is already an Order for the current date and of the current type
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : unable to get storeID"); return
        }

        /// TODO: should we first check if there are any valid Inventories to use for generating the Orders?
        /// TODO: break out into `createAlertController() -> UIAlertController`
        let alertController = UIAlertController(
            title: "Create Order", message: "Set order quantities from the most recent inventory or simply use pars?",
            preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: "From Count", style: .default, handler: { (_) in
            self.createOrderCollection(storeID: storeID, generateFrom: .count)
        }))
        alertController.addAction(UIAlertAction(title: "From Par", style: .default, handler: { (_) in
            self.createOrderCollection(storeID: storeID, generateFrom: .par)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)

    }

     */
}

// MARK: - Alert

enum GenerationMethod: CustomStringConvertible {
    //case count(method: NewOrderGenerationMethod)
    //case par(method: NewOrderGenerationMethod)
    case count
    case par
    //case sales
    case cancel

    var description: String {
        switch self {
        case .count:
            return "From Count"
        case .par:
            return "From Par"
        case .cancel:
            return "Cancel"
        }
    }
}

// MARK: - TableViewDelegate
extension OrderDateViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObjects.onNext(dataSource.objectAtIndexPath(indexPath))
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension OrderDateViewController: TableViewDataSourceDelegate {

    func canEdit(_ collection: OrderCollection) -> Bool {
        switch collection.uploaded {
        case true:
            return false
        case false:
            return true
        }
    }

    func configure(_ cell: UITableViewCell, for collection: OrderCollection) {
        cell.textLabel?.text = collection.date.altStringFromDate()

        switch collection.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        }
    }

}

/*
// MARK: - Completion Handlers + Sync
extension OrderDateViewController {

    // MARK: Completion Handlers

    func completedGetListOfOrderCollections(json: JSON?, error: Error?) {
        refreshControl?.endRefreshing()
        guard error == nil else {
            //if error?._code == NSURLErrorTimedOut {}
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.warning("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }

        do {
            try managedObjectContext.syncCollections(OrderCollection.self, withJSON: json)
        } catch {
            log.error("Unable to sync OrderCollections")
            HUD.flash(.error, delay: 1.0)
        }
        HUD.hide()
        managedObjectContext.performSaveOrRollback()
        tableView.reloadData()
    }

    func completedGetExistingOrderCollection(json: JSON?, error: Error?) {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.flash(.error, delay: 1.0); return
        }

        guard let selection = selectedCollection else {
            log.error("\(#function) FAILED : still unable to get selected OrderCollection\n")
            HUD.flash(.error, delay: 1.0); return
        }

        selection.update(in: managedObjectContext!, with: json)
        managedObjectContext!.performSaveOrRollback()

        //tableView.activityIndicatorView.stopAnimating()
        HUD.hide()
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedGetNewOrderCollection(json: JSON?, error: Error?) {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.flash(.error, delay: 1.0); return
        }

        log.verbose("Creating new OrderCollection ...")
        selectedCollection = OrderCollection(context: managedObjectContext!, json: json, uploaded: false)
        managedObjectContext!.performSaveOrRollback()

        HUD.hide()
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedSync(_ succeeded: Bool, _ error: Error?) {
        if succeeded {
            log.info("Completed login / sync - succeeded: \(succeeded)")
            guard let storeID = userManager.storeID else {
                log.error("\(#function) FAILED : unable to get storeID")
                HUD.flash(.error, delay: 1.0); return
            }

            log.verbose("Fetching existing OrderCollections from server ...")
            APIManager.sharedInstance.getListOfOrderCollections(storeID: storeID,
                                                                completion: self.completedGetListOfOrderCollections)
        } else {
            log.error("Unable to login / sync ...")
            // if let error = error { // present more detailed error ...
            HUD.flash(.error, delay: 1.0)
        }
    }

    // MARK: Sync

    // Source: https://code.tutsplus.com/tutorials/core-data-and-swift-batch-deletes--cms-25380
    /// NOTE: I believe I scrapped a plan to make this a method because of the involvement of the moc
    func deleteChildOrders(parent: OrderCollection) {
        let fetchPredicate = NSPredicate(format: "collection == %@", parent)
        do {
            try managedObjectContext.deleteEntities(Order.self, filter: fetchPredicate)

            /// TODO: perform fetch again?
            //let request: NSFetchRequest<Inventory> = Inventory.fetchRequest()
            //let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            //request.sortDescriptors = [sortDescriptor]
            //dataSource.reconfigureFetchRequest(request)

            // Reload Table View
            tableView.reloadData()

        } catch {
            let updateError = error as NSError
            log.error("Unable to delete Orders: \(updateError), \(updateError.userInfo)")
        }
    }

}
*/
