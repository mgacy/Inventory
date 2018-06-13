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
class InventoryLocationViewController: UIViewController, AttachableType {

    // MARK: - Properties

    var bindings: InventoryLocationViewModel.Bindings {
        return InventoryLocationViewModel.Bindings(
            cancelTaps: cancelButtonItem.rx.tap.asObservable(),
            rowTaps: tableView.rx.itemSelected.asObservable(),
            uploadTaps: uploadButtonItem.rx.tap.asObservable()
        )
    }
    var viewModel: Attachable<InventoryLocationViewModel>!
    let dismissView: Observable<Void>

    private let disposeBag = DisposeBag()
    private let _dismissView = PublishSubject<Void>()

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

    required init?(coder aDecoder: NSCoder) {
        dismissView = _dismissView.asObservable()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.presentingViewController != nil {
            self.navigationItem.leftBarButtonItem = cancelButtonItem
        }
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

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
        // ActivityIndicator
        // MessageLabel
    }

    func bind(viewModel: InventoryLocationViewModel) -> InventoryLocationViewModel {
        // We have to wait until after we set .viewModel since we use viewModel.frc
        setupTableView(with: viewModel)

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
                        self?._dismissView.onNext(())
                    }
                case .error:
                    /// TODO: `case.error(let error):; switch error {}`
                    UIViewController.showErrorInHUD(title: Strings.errorAlertTitle, subtitle: "Message")
                case .completed:
                    log.warning("\(#function) : not sure how to handle completion")
                }
            })
            .disposed(by: disposeBag)

        return viewModel
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryLocationViewController>!

    fileprivate func setupTableView(with viewModel: InventoryLocationViewModel) {
        //tableView.refreshControl = refreshControl
        tableView.register(cellType: UITableViewCell.self)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView()
        dataSource = TableViewDataSource(tableView: tableView, fetchedResultsController: viewModel.frc, delegate: self)
    }

}

// MARK: - TableViewDelegate
extension InventoryLocationViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
                cell.textLabel?.textColor = ColorPalette.yellow
            case .complete:
                cell.textLabel?.textColor = UIColor.black
            }
        }
    }

}
