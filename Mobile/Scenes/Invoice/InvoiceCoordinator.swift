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

        // Selection
        viewModel.showCollection
            .flatMap { [weak self] selection -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.showVendorList(collection: selection)
            }
            //.debug("itemSelection - \(viewController)")
            .subscribe()
            .disposed(by: viewController.disposeBag)

        return Observable.never()
    }

    // MARK: - Sections

    private func showVendorList(collection: InvoiceCollection) -> Observable<Void> {
        let viewController = InvoiceVendorViewController()
        let viewModel = InvoiceVendorViewModel(
            dependency: InvoiceVendorViewModel.Dependency(dataManager: dependencies.dataManager,
                                                          parentObject: collection),
            bindings: viewController.bindings)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        // Selection
        viewModel.selectedItem
            .asObservable()
            .flatMap { [weak self] invoice -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.showItemList(invoice: invoice)
            }
            //.debug("itemSelection - \(viewController)")
            .subscribe()
            .disposed(by: viewController.disposeBag)

        /*
        // Selection
        let selectionDisposable = viewModel.selectedItem
            .flatMap { [weak self] invoice -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.showItemList(invoice: invoice)
            }
            .debug("itemSelection - \(viewController)")
            .subscribe()
        */
        return viewController.wasPopped
            .take(1)
            //.do(onNext: { _ in selectionDisposable.dispose() })
    }

    private func showItemList(invoice: Invoice) -> Observable<Void> {
        let viewController = InvoiceItemViewController()
        let viewModel = InvoiceItemViewModel(
            dependency: InvoiceItemViewModel.Dependency(dataManager: dependencies.dataManager, parentObject: invoice),
            bindings: viewController.bindings)
        viewController.viewModel = viewModel
        navigationController.showDetailViewController(viewController, sender: nil)
        /*
        // Selection (A)
        //let selectionDisposable = viewController.tableView.rx.itemSelected
        let selectionDisposable = viewModel.itemSelected
            .flatMap { [weak self] indexPath -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.showKeypad(invoice: invoice, atIndex: indexPath.row)
            }
            .do(onNext: { _ in
                // Deselect
                if let selectedRowIndexPath = viewController.tableView.indexPathForSelectedRow {
                    viewController.tableView.deselectRow(at: selectedRowIndexPath, animated: true)
                }
            })
            //.debug("itemSelection - \(viewController)")
            .subscribe()

        return viewController.wasPopped
            .take(1)
            .do(onNext: { _ in selectionDisposable.dispose() })
        */

        // Selection (B)
        //viewController.tableView.rx.itemSelected
        viewModel.itemSelected
            .flatMap { [weak self] indexPath -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.showKeypad(invoice: invoice, atIndex: indexPath.row)
            }
            .do(onNext: { [tableView = viewController.tableView] in
                // Deselect; subscription won't dispose and VC won't deinit w/o the above capture list
                // see: https://www.objc.io/blog/2018/04/03/caputure-lists/
                if let selectedRowIndexPath = tableView.indexPathForSelectedRow {
                    tableView.deselectRow(at: selectedRowIndexPath, animated: true)
                }
            })
            .debug("itemSelection - \(viewController)")
            .subscribe()
            .disposed(by: viewController.disposeBag)

        return viewController.wasPopped
            .take(1)
    }

    private func showKeypad(invoice: Invoice, atIndex index: Int) -> Observable<Void> {
        let keypadCoordinator = InvoiceKeypadCoordinator(rootViewController: navigationController,
                                                         dependencies: dependencies, invoice: invoice, atIndex: index)
        return coordinate(to: keypadCoordinator)
    }

}
