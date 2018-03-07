//
//  SettingsViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SettingsViewController: UITableViewController, AttachableType {

    enum Strings {
        static let navTitle = "Settings"
    }

    lazy var bindings: SettingsViewModel.Bindings = {
        return SettingsViewModel.Bindings(
            selection: tableView.rx.itemSelected.asDriver()
        )
    }()

    let disposeBag = DisposeBag()
    var viewModel: Attachable<SettingsViewModel>!

    // MARK: - Interface
    let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
    @IBOutlet weak var accountCell: UITableViewCell!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    // MARK: - View Methods

    private func setupView() {
        title = Strings.navTitle
        navigationItem.rightBarButtonItem = doneButtonItem
    }

    func bind(viewModel: SettingsViewModel) -> SettingsViewModel {
        viewModel.didLogout
            .drive()
            .disposed(by: disposeBag)

        viewModel.accountCellText
            .drive(accountCell.textLabel!.rx.text)
            .disposed(by: disposeBag)

        return viewModel
    }

}
