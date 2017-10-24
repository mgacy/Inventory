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
        configureAccountCell()
    }

    //private func setupConstraints() {}

    private func setupBindings() {
        viewModel.didLogout
            .drive(onNext: { [weak self] _ in
                self?.accountCell.textLabel?.text = "Login"
            })
            .disposed(by: disposeBag)

        viewModel.showLogin
            .drive(onNext: { [weak self] _ in
                log.verbose("Showing AccountVC ...")
                guard let strongSelf = self else { fatalError("Unable to get self") }
                strongSelf.performSegue(withIdentifier: strongSelf.accountSegue, sender: self)
                /*
                let controller = LoginViewController.initFromStoryboard(name: "Main")
                controller.userManager = strongSelf.viewModel.dataManager.userManager
                /// TODO: fix how we show controller
                strongSelf.navigationController?.pushViewController(controller, animated: true)
                */
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case accountSegue:
            guard
                let destinationNavController = segue.destination as? UINavigationController,
                let destinationController = destinationNavController.topViewController as? LoginViewController
            else {
                fatalError("Wrong view controller type")
            }
            /// FIXME: change this
            destinationController.userManager = viewModel.dataManager.userManager
        default:
            break
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.verbose("Selected section \(indexPath.section)")
        rowTaps.onNext(indexPath)
        /*
        // Account
        if indexPath.section == 0 {
            if let user = userManager.user {
                log.verbose("Logging out \(user.email)")

                /// TODO: check for pending Inventory / Invoice / Order
                /// TODO: if so, present warning

                userManager.logout(completion: completedLogout)
            } else {
                log.verbose("Showing AccountVC ...")
                performSegue(withIdentifier: accountSegue, sender: self)
            }
        }
        */
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - User Actions

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
