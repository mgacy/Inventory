//
//  InventoryLocationViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
//import CoreData
//import SwiftyJSON
import PKHUD
import RxCocoa
import RxSwift

// swiftlint:disable:next type_name
class InventoryLocationViewController: UIViewController, SegueHandler {

    // MARK: - Properties

    var viewModel: InventoryLocationViewModel!
    let disposeBag = DisposeBag()

    let selectedObjects = PublishSubject<InventoryLocation>()

    // TableViewCell
    let cellIdentifier = "InventoryLocationTableViewCell"

    // Segues
    enum SegueIdentifier: String {
        case showCategory = "ShowLocationCategory"
        case showItem = "ShowLocationItem"
    }

    // MARK: - Interface

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!

    let uploadButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Upload"), style: UIBarButtonItemStyle.plain, target: nil, action: nil)

    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.delegate = self
        return tv
    }()

    private enum Strings {
        static let navTitle = "Locations"
        static let errorAlertTitle = "Error"
    }

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.warning("\(#function)")
        // Dispose of any resources that can be recreated.
    }

    // MARK: - View Methods

    private func setupView() {
        title = Strings.navTitle
        /// TODO: add `messageLabel` output to viewModel?
        //messageLabel.text = "You do not have any Items yet."

        self.navigationItem.rightBarButtonItem = uploadButtonItem

        //activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        //messageLabel.translatesAutoresizingMaskIntoConstraints = false

        //self.view.addSubview(activityIndicatorView)
        //self.view.addSubview(messageLabel)
        self.view.addSubview(tableView)
    }

    private func setupConstraints() {
        // TableView
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        /*
         // ActivityIndicator
         activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
         activityIndicatorView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
         activityIndicatorView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true

         // MessageLabel
         //messageLabel.translatesAutoresizingMaskIntoConstraints = false
         messageLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
         messageLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true
         */
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
                    HUD.flash(.success, delay: 1.0)
                    /// TODO: this should be handled elsewhere
                    self?.navigationController!.popViewController(animated: true)
                case .error:
                    /// TODO: `case.error(let error):; switch error {}`
                    UIViewController.showErrorInHUD(title: Strings.errorAlertTitle, subtitle: "Message")
                case .completed:
                    log.warning("\(#function) : not sure how to handle completion")
                }
            })
            .disposed(by: disposeBag)
        /*
        // Errors
        viewModel.errorMessages
            .drive(onNext: { [weak self] message in
                log.error("Error: \(message)")
                //self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)
         */
        // Selection
        viewModel.showLocation
            .subscribe(onNext: { [weak self] selection in
                log.debug("\(#function) SELECTED: \(selection)")
                guard let strongSelf = self else {
                    log.error("\(#function) FAILED : unable to get reference to self"); return
                }

                switch selection {
                //case .back:
                case .category(let location):
                    let vc = InventoryLocationCategoryTVC.initFromStoryboard(name: "Main")
                    vc.location = location
                    vc.managedObjectContext = strongSelf.viewModel.dataManager.managedObjectContext
                    strongSelf.navigationController?.pushViewController(vc, animated: true)
                case .item(let location):
                    let vc = InventoryLocationItemTVC.initFromStoryboard(name: "Main")
                    vc.location = location
                    vc.title = location.name ?? "Error"
                    vc.managedObjectContext = strongSelf.viewModel.dataManager.managedObjectContext
                    strongSelf.navigationController?.pushViewController(vc, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: Navigation
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let selection = selectedLocation else { fatalError("Showing detail, but no selected row?") }

        switch segueIdentifier(for: segue) {
        case .showCategory:
            guard let destinationController = segue.destination as? InventoryLocationCategoryTVC else {
                fatalError("Wrong view controller type")
            }
            destinationController.location = selection
            destinationController.managedObjectContext = self.managedObjectContext

        case .showItem:
            guard let destinationController = segue.destination as? InventoryLocationItemTVC else {
                fatalError("Wrong view controller type")
            }
            destinationController.title = selection.name
            destinationController.location = selection
            destinationController.managedObjectContext = self.managedObjectContext
        }
    }
     */
    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryLocationViewController>!
    //fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        //tableView.refreshControl = refreshControl
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        /*
        //let request = Mood.sortedFetchRequest(with: moodSource.predicate)
        let request: NSFetchRequest<InventoryLocation> = InventoryLocation.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        let fetchPredicate = NSPredicate(format: "inventory == %@", inventory)
        request.predicate = fetchPredicate

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!,
                                             sectionNameKeyPath: nil, cacheName: nil)
         */
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }

    // MARK: - User Actions

    @IBAction func uploadTapped(_ sender: AnyObject) {
        log.info("Uploading Inventory ...")
        /*
        HUD.show(.progress)

        guard let dict = self.inventory.serialize() else {
            log.error("\(#function) FAILED : unable to serialize Inventory")
            /// TODO: completedUpload(false)
            return
        }
        APIManager.sharedInstance.postInventory(inventory: dict, completion: self.completedUpload)
         */
    }

}

// MARK: - TableViewDelegate
extension InventoryLocationViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObjects.onNext(dataSource.objectAtIndexPath(indexPath))
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
/*
// MARK: - Completion Handlers
extension InventoryLocationViewController {

    func completedUpload(json: JSON?, error: Error?) {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.error("\(#function) FAILED: unable to get JSON")
            HUD.flash(.error, delay: 1.0); return
        }
        guard let remoteID = json["id"].int else {
            log.error("\(#function) FAILED: unable to get remoteID of posted Inventory")
            HUD.flash(.error, delay: 1.0); return
        }

        inventory.uploaded = true
        inventory.remoteID = Int32(remoteID)

        HUD.flash(.success, delay: 1.0)
        navigationController!.popViewController(animated: true)
    }

}
*/
// MARK: - TableViewDataSourceDelegate Extension
extension InventoryLocationViewController: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for location: InventoryLocation) {
        cell.textLabel?.text = location.name

        if let status = location.status {
            switch status {
            case .notStarted:
                cell.textLabel?.textColor = UIColor.lightGray
            case .incomplete:
                cell.textLabel?.textColor = ColorPalette.yellowColor
            case .complete:
                cell.textLabel?.textColor = UIColor.black
            }
        }
    }

}

