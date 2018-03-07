//
//  InvoiceCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class InvoiceCoordinator: BaseCoordinator<Void> {
    typealias Dependencies = HasDataManager

    private let navigationController: UINavigationController
    private let dependencies: Dependencies

    init(navigationController: UINavigationController, dependencies: Dependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    override func start() -> Observable<Void> {
        let viewController = InvoiceDateViewController.instance()
        let viewModel = InvoiceDateViewModel(dataManager: dependencies.dataManager,
                                             rowTaps: viewController.selectedObjects.asObservable())
        viewController.viewModel = viewModel
        navigationController.viewControllers = [viewController]

        // Selction
        viewModel.showCollection
            .subscribe(onNext: { [weak self] selection in
                log.debug("\(#function) SELECTED / CREATED: \(selection)")
                self?.showVendorList(collection: selection)
            })
            .disposed(by: disposeBag)

        return Observable.never()
    }

    // MARK: - Sections

    private func showVendorList(collection: InvoiceCollection) {
        let viewController = InvoiceVendorViewController.initFromStoryboard(name: "InvoiceVendorViewController")
        let viewModel = InvoiceVendorViewModel(dataManager: dependencies.dataManager, parentObject: collection)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        // Selection
        viewController.selectedObjects
            .subscribe(onNext: { [weak self] invoice in
                self?.showItemList(invoice: invoice)
            })
            .disposed(by: disposeBag)
    }

    private func showItemList(invoice: Invoice) {
        let viewController = InvoiceItemViewController.initFromStoryboard(name: "InvoiceItemViewController")
        let viewModel = InvoiceItemViewModel(dataManager: dependencies.dataManager, parentObject: invoice,
                                             uploadTaps: viewController.uploadButtonItem.rx.tap.asObservable())
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        /// TODO: handle pop on uploadResults?

        // Selection
        viewController.selectedIndices
            .subscribe(onNext: { [weak self] indexPath in
                self?.showKeypad(invoice: invoice, atIndex: indexPath.row)
            })
            .disposed(by: disposeBag)
    }

    private func showKeypad(invoice: Invoice, atIndex index: Int) {
        let viewController = InvoiceKeypadViewController.instance()
        let viewModel = InvoiceKeypadViewModel(dataManager: dependencies.dataManager, for: invoice, atIndex: index)
        viewController.viewModel = viewModel
        navigationController.showDetailViewController(viewController, sender: nil)
    }

}
