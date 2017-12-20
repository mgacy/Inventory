//
//  SettingsCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/23/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class SettingsCoordinator: BaseCoordinator<Void> {

    private let rootViewController: UIViewController
    private let dataManager: DataManager

    init(rootViewController: UIViewController, dataManager: DataManager) {
        self.rootViewController = rootViewController
        self.dataManager = dataManager
    }

    override func start() -> Observable<CoordinationResult> {
        let viewController = SettingsViewController.initFromStoryboard(name: "SettingsViewController")
        let navigationController = UINavigationController(rootViewController: viewController)

        let viewModel = SettingsViewModel(dataManager: dataManager, rowTaps: viewController.rowTaps.asObservable())
        viewController.viewModel = viewModel

        viewModel.showLogin
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let strongSelf = self else { return Observable.just(()) }
                return strongSelf.showLogin(on: viewController)
            }
            .subscribe()
            .disposed(by: disposeBag)

        if let navVC = rootViewController.parent as? UINavigationController, let tabVC = navVC.parent,
           let splitVC = tabVC.parent, splitVC.traitCollection.horizontalSizeClass == .regular {
            navigationController.modalPresentationStyle = .formSheet
        }
        rootViewController.present(navigationController, animated: true)

        return viewController.doneButtonItem.rx.tap
            .take(1)
            .do(onNext: { [weak self] _ in self?.rootViewController.dismiss(animated: true) })
    }

    private func showLogin(on rootViewController: UIViewController) -> Observable<Void> {
        let loginCoordinator = LoginCoordinator(rootViewController: rootViewController, dataManager: dataManager)
        return coordinate(to: loginCoordinator)
    }

}
