//
//  InvoiceKeypadCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/22/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import RxCocoa
import RxSwift

final class InvoiceKeypadCoordinator: BaseCoordinator<Void> {
    typealias Dependencies = HasDataManager

    private let rootViewController: UIViewController
    private let dependencies: Dependencies
    private let invoice: Invoice
    private let index: Int

    init(rootViewController: UIViewController, dependencies: Dependencies, invoice: Invoice, atIndex index: Int) {
        self.rootViewController = rootViewController
        self.dependencies = dependencies
        self.invoice = invoice
        self.index = index
    }

    override func start() -> Observable<Void> {
        let viewController = InvoiceKeypadViewController()
        let viewModel = InvoiceKeypadViewModel(dataManager: dependencies.dataManager, for: invoice, atIndex: index)
        viewController.viewModel = viewModel

        let presentedViewController: UIViewController & ModalKeypadDismissing
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            presentedViewController = viewController
        case .pad:
            /// TODO: use rootViewController dimensions to configure modalViewController constraints
            presentedViewController = ModalKeypadViewController(keypadViewController: viewController)
        default:
            fatalError("Unable to setup bindings for unrecognized device: \(UIDevice.current.userInterfaceIdiom)")
        }

        rootViewController.present(presentedViewController, animated: true)

        return presentedViewController.dismissalEvents
            .take(1)
            .do(onNext: { [weak self] _ in self?.rootViewController.dismiss(animated: true) })
    }

}
