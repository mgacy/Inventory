//
//  OrderContainerViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/1/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
//import RxCocoa
//import RxSwift

class OrderContainerViewController: UIViewController {

    private enum Strings {
        static let locationsNavTitle = "Locations"
        static let vendorsNavTitle = "Vendors"
        static let errorAlertTitle = "Error"
    }

    // MARK: - Properties

    var viewModel: OrderContainerViewModel!
    //let disposeBag = DisposeBag()

    // MARK: - Interface

    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["Vendors", "Locations"]
        let control = UISegmentedControl(items: items)
        control.addTarget(self, action: #selector(selectionDidChange(_:)), for: .valueChanged)
        control.selectedSegmentIndex = 0
        return control
    }()

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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        //setupConstraints()
        //setupBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        navigationItem.titleView = segmentedControl
        //navigationItem.leftBarButtonItem =
        //navigationItem.rightBarButtonItem =
        updateView()
    }

    private func updateView() {
        if segmentedControl.selectedSegmentIndex == 0 {
            remove(asChildViewController: locationsViewController)
            add(asChildViewController: vendorsViewControlller)
            title = Strings.vendorsNavTitle
        } else {
            remove(asChildViewController: vendorsViewControlller)
            add(asChildViewController: locationsViewController)
            title = Strings.locationsNavTitle
        }
    }

    //private func setupConstraints() {}

    //private func setupBindings() {}

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
