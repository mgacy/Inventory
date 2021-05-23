//
//  HomeViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/7/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import PKHUD
import RxCocoa
import RxSwift

class HomeViewController: UIViewController, AttachableType {

    private enum Strings {
        // TODO: navTitle should be store name
        static let navTitle = "Home"
        static let errorAlertTitle = "Error"
        static let newOrderTitle = "Create Order"
        static let newOrderMessage = "Set order quantities from the most recent inventory or simply use pars?"
    }

    // MARK: - Alert
    private enum GenerationMethod: CustomStringConvertible {
        case count
        case par
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

        var method: NewOrderGenerationMethod {
            switch self {
            case .count:
                return NewOrderGenerationMethod.count
            case .par:
                return NewOrderGenerationMethod.par
            default:
                return NewOrderGenerationMethod.par
            }
        }
    }

    // MARK: - Properties

    var bindings: HomeViewModel.Bindings {
        return HomeViewModel.Bindings(
            addInventoryTaps: addInventoryButton.rx.tap.asObservable(),
            // FIXME: is this safe?
            addOrderTaps: addOrderButton.rx.tap.flatMap { [unowned self] _ in return self.mapAlert() },
            selection: childViewController.tableView.rx.itemSelected.asDriver()
        )
    }
    var viewModel: Attachable<HomeViewModel>!
    let disposeBag = DisposeBag()

    // MARK: - Interface
    let settingsButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Settings"), style: .plain, target: nil, action: nil)
    lazy var childViewController = PendingViewController(style: .plain)

    @IBOutlet weak var addInventoryButton: UIButton!
    @IBOutlet weak var addOrderButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        //title = Strings.navTitle
        self.navigationItem.leftBarButtonItem = settingsButtonItem
        //self.navigationItem.rightBarButtonItem =
        embedViewController()
    }

    //private func setupConstraints() {}

    private func embedViewController() {
        let guide: UILayoutGuide
        if #available(iOS 11, *) {
            guide = view.safeAreaLayoutGuide
        } else {
            guide = view.layoutMarginsGuide
        }

        let constraints = [
            childViewController.view.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 0),
            childViewController.view.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: 0),
            childViewController.view.heightAnchor.constraint(equalToConstant: 132),
            childViewController.view.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -108)
        ]
        add(childViewController, with: constraints)
    }

    func bind(viewModel: HomeViewModel) -> HomeViewModel {
        viewModel.storeName
            .drive(self.rx.title)
            .disposed(by: disposeBag)

        viewModel.isLoading
            .drive(onNext: { status in
                switch status {
                case true:
                    HUD.show(.progress)
                case false:
                    HUD.hide()
                }
            })
            .disposed(by: disposeBag)

        viewModel.errorMessages
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)

        // MARK: TableView
        viewModel.pendingInventoryCount
            .drive(childViewController.inventoryCell.detailTextLabel!.rx.text)
            .disposed(by: disposeBag)

        viewModel.pendingOrderCount
            .drive(childViewController.orderCell.detailTextLabel!.rx.text)
            .disposed(by: disposeBag)

        viewModel.pendingInvoiceCount
            .drive(childViewController.invoiceCell.detailTextLabel!.rx.text)
            .disposed(by: disposeBag)

        return viewModel
    }

    private func mapAlert() -> Observable<NewOrderGenerationMethod> {
        let actions: [GenerationMethod] = [.count, .par]
        return promptFor(title: Strings.newOrderTitle, message: Strings.newOrderMessage, cancelAction: .cancel,
                         actions: actions)
            .filter { $0 != .cancel }
            .map { $0.method }
    }

}

// MARK: - childViewController

final class PendingViewController: UITableViewController {

    // MARK: - Interface

    var inventoryCell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: nil)
    var orderCell: UITableViewCell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    var invoiceCell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: nil)

    // MARK: - Lifecycle

    override func loadView() {
        super.loadView()
        tableView.isScrollEnabled = false

        // Cells
        inventoryCell.textLabel?.text = "Inventories"
        orderCell.textLabel?.text = "Orders"
        invoiceCell.textLabel?.text = "Invoices"
    }

    // MARK: - UITableViewDatasource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0: return self.inventoryCell
        case 1: return self.orderCell
        case 2: return invoiceCell
        default: fatalError("Unknown row in section 0")
        }
    }

}
