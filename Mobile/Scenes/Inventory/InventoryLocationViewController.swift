//
//  InventoryLocationViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import PKHUD
import RxCocoa
import RxSwift

// swiftlint:disable:next type_name
class InventoryLocationViewController: UIViewController {

    // MARK: - Properties

    var viewModel: InventoryLocationViewModel!
    let disposeBag = DisposeBag()

    let selectedIndices = PublishSubject<IndexPath>()

    // TableViewCell
    let cellIdentifier = "InventoryLocationTableViewCell"

    // MARK: - Interface

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!

    let cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: nil, action: nil)
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
        if self.presentingViewController != nil {
            self.navigationItem.leftBarButtonItem = cancelButtonItem
        }

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
        // ActivityIndicator
        // MessageLabel
    }

    private func setupBindings() {

        // Cancel Button
         if self.presentingViewController != nil {
            cancelButtonItem.rx.tap.asObservable()
                .subscribe(onNext: { [weak self] _ in
                    self?.navigationController?.dismiss(animated: true)
                })
                .disposed(by: disposeBag)
        }

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
                        if self?.presentingViewController != nil {
                            self?.navigationController?.dismiss(animated: true)
                        } else {
                            self?.navigationController!.popViewController(animated: true)
                        }
                    }
                case .error:
                    /// TODO: `case.error(let error):; switch error {}`
                    UIViewController.showErrorInHUD(title: Strings.errorAlertTitle, subtitle: "Message")
                case .completed:
                    log.warning("\(#function) : not sure how to handle completion")
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryLocationViewController>!

    fileprivate func setupTableView() {
        //tableView.refreshControl = refreshControl
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - TableViewDelegate
extension InventoryLocationViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndices.onNext(indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate
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
