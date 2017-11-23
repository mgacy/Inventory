//
//  OrderContainerViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/1/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class OrderContainerViewController: UIViewController {

    private enum Strings {
        static let locationsNavTitle = "Locations"
        static let vendorsNavTitle = "Vendors"
        static let errorAlertTitle = "Error"
        static let confirmCompleteTitle = "Warning: Pending Orders"
        static let confirmCompleteMessage = "Marking order collection as completed will delete any pending " +
        "orders. Are you sure you want to proceed?"
    }

    // MARK: - Properties

    var viewModel: OrderContainerViewModel!
    let disposeBag = DisposeBag()

    let confirmComplete = PublishSubject<Void>()

    // MARK: - Interface

    let cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: nil, action: nil)
    let completeButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "DoneBarButton"), style: .done, target: nil, action: nil)

    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["Vendors", "Locations"]
        let control = UISegmentedControl(items: items)
        control.addTarget(self, action: #selector(selectionDidChange(_:)), for: .valueChanged)
        control.selectedSegmentIndex = 0
        return control
    }()

    private var vendorsViewControlller: OrderVendorViewController!
    private var locationsViewController: OrderLocationViewController!
    /*
    private lazy var vendorsViewControlller: OrderVendorViewController = {
        let controller = OrderVendorViewController.initFromStoryboard(name: "OrderVendorViewController")
        controller.viewModel = OrderVendorViewModel(dataManager: self.viewModel.dataManager,
                                                    parentObject: self.viewModel.parentObject,
                                                    rowTaps: controller.selectedObjects.asObservable(),
                                                    completeTaps: controller.completeButtonItem.rx.tap.asObservable())

        self.add(asChildViewController: controller)
        return controller
    }()

    private lazy var locationsViewController: OrderLocationViewController = {
        guard let viewController = OrderLocationViewController.instance() else {
            fatalError("\(#function) FAILED : wrong view controller")
        }
        viewController.viewModel = OrderLocationViewModel(dataManager: self.viewModel.dataManager,
                                                          collection: self.viewModel.parentObject)

        self.add(asChildViewController: viewController)
        return viewController
    }()
    */
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        //setupConstraints()
        setupBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    func configureChildControllers(vendorsController: OrderVendorViewController, locationsController: OrderLocationViewController) {
        vendorsViewControlller = vendorsController
        locationsViewController = locationsController
    }

    private func setupView() {
        navigationItem.titleView = segmentedControl
        navigationItem.rightBarButtonItem = completeButtonItem
        if self.presentingViewController != nil {
            self.navigationItem.leftBarButtonItem = cancelButtonItem
        }
        updateView()
    }

    private func updateView() {
        if segmentedControl.selectedSegmentIndex == 0 {
            remove(asChildViewController: locationsViewController)
            add(asChildViewController: vendorsViewControlller)
            title = Strings.vendorsNavTitle
            completeButtonItem.isEnabled = true
        } else {
            remove(asChildViewController: vendorsViewControlller)
            add(asChildViewController: locationsViewController)
            title = Strings.locationsNavTitle
            completeButtonItem.isEnabled = false
        }
    }

    //private func setupConstraints() {}

    private func setupBindings() {
        // Cancel Button
        if self.presentingViewController != nil {
            cancelButtonItem.rx.tap.asObservable()
                .subscribe(onNext: { [weak self] _ in
                    self?.navigationController?.dismiss(animated: true)
                })
                .disposed(by: disposeBag)
        }

        // Complete Order Alert
        viewModel.showAlert
            .drive(onNext: { [weak self] _ in
                self?.showAlert(title: Strings.confirmCompleteTitle, message: Strings.confirmCompleteMessage) {
                    self?.confirmComplete.onNext(())
                }
            })
            .disposed(by: disposeBag)

        confirmComplete.asObservable()
            .bind(to: viewModel.confirmComplete)
            .disposed(by: disposeBag)

        // Navigation
        /// TODO: move into OrderCoordinator
        viewModel.popView
            .drive(onNext: { [weak self] in
                if self?.presentingViewController != nil {
                    self?.navigationController?.dismiss(animated: true)
                } else {
                    self?.navigationController!.popViewController(animated: true)
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Actions

    @objc func selectionDidChange(_ sender: UISegmentedControl) {
        updateView()
    }

    // MARK: - Helper Methods

    private func add(asChildViewController viewController: UIViewController) {
        // Add Child View Controller
        addChildViewController(viewController)

        // Add Child View as Subview
        view.addSubview(viewController.view)

        // Configure Child View
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Notify Child View Controller
        viewController.didMove(toParentViewController: self)
    }

    private func remove(asChildViewController viewController: UIViewController) {
        // Notify Child View Controller
        viewController.willMove(toParentViewController: nil)

        // Remove Child View From Superview
        viewController.view.removeFromSuperview()

        // Notify Child View Controller
        viewController.removeFromParentViewController()
    }

}
