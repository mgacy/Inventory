//
//  InvoiceCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class InvoiceCoordinator: BaseCoordinator<Void> {

    private let navigationController: UINavigationController
    private let dataManager: DataManager

    init(navigationController: UINavigationController, dataManager: DataManager) {
        self.navigationController = navigationController
        self.dataManager = dataManager
    }

    override func start() -> Observable<Void> {
        let viewController = InvoiceDateViewController.initFromStoryboard(name: "Main")
        let viewModel = InvoiceDateViewModel(dataManager: dataManager,
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
        let viewModel = InvoiceVendorViewModel(dataManager: dataManager, parentObject: collection)
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
        let viewModel = InvoiceItemViewModel(dataManager: dataManager, parentObject: invoice,
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
        guard let viewController = InvoiceKeypadViewController.instance() else {
            fatalError("\(#function) FAILED: unable to get destination view controller.")
        }
        let viewModel = InvoiceKeypadViewModel(dataManager: dataManager, for: invoice, atIndex: index)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)
    }

}
