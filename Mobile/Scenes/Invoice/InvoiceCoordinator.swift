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
        navigationController.showDetailViewController(viewController, sender: nil)

        let itemSelection = viewController.tableView.rx
            .itemSelected
            .map { [weak self] indexPath -> Observable<Void> in
                log.debug("We selected: \(indexPath)")
                //return self?.showKeypad(invoice: invoice, atIndex: indexPath.row)
                guard let strongSelf = self else { return .just(()) }
                return strongSelf.showKeypad(invoice: invoice, atIndex: indexPath.row)
            }
            .do(onNext: { _ in
                // Deselect
                if let selectedRowIndexPath = viewController.tableView.indexPathForSelectedRow {
                    viewController.tableView.deselectRow(at: selectedRowIndexPath, animated: true)
                }
            })

        itemSelection
            //.debug()
            .subscribe()
            .disposed(by: viewController.disposeBag)
    }

    private func showKeypad(invoice: Invoice, atIndex index: Int) -> Observable<Void> {
        let keypadCoordinator = ModalInvoiceKeypadCoordinator(rootViewController: navigationController,
                                                              dependencies: dependencies, invoice: invoice,
                                                              atIndex: index)
        return coordinate(to: keypadCoordinator)
    }

}
