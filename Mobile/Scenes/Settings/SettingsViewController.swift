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

class SettingsViewController: UITableViewController {

    enum Strings {
        static let navTitle = "Settings"
    }

    // MARK: Properties

    var viewModel: SettingsViewModel!
    let disposeBag = DisposeBag()
    let rowTaps = PublishSubject<IndexPath>()

    // Segues
    let accountSegue = "showAccount"

    // MARK: - Interface
    let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)

    @IBOutlet weak var accountCell: UITableViewCell!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        configureAccountCell()
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        title = Strings.navTitle
        navigationItem.rightBarButtonItem = doneButtonItem
        configureAccountCell()
    }

    //private func setupConstraints() {}

    private func setupBindings() {
        viewModel.didLogout
            .drive(onNext: { [weak self] _ in
                self?.accountCell.textLabel?.text = "Login"
            })
            .disposed(by: disposeBag)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.verbose("Selected section \(indexPath.section)")
        rowTaps.onNext(indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Configuration

    /// TODO: pass User?
    func configureAccountCell() {
        if let user = viewModel.currentUser {
            accountCell.textLabel?.text = "Logout \(user.email)"
        } else {
            accountCell.textLabel?.text = "Login"
        }
    }

}
