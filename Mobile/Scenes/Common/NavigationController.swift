//
//  NavigationController.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/12/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController, PrimaryContainerType {
    /// TODO: should this be weak var?
    let detailPopCompletion: (UIViewController & PlaceholderViewControllerType) -> Void
    var detailView: DetailView = .placeholder

    // MARK: - Lifecycle

    init(withPopDetailCompletion completion: @escaping (UIViewController & PlaceholderViewControllerType) -> Void) {
        self.detailPopCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = false
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        switch detailView {
        case .collapsed:
            detailView = .placeholder
        case .separated:
            detailView = .placeholder
            // Set detail view controller to `PlaceholderViewControllerType` to prevent confusion
            detailPopCompletion(makePlaceholderViewController())
        case .placeholder:
            break
        }
        return super.popViewController(animated: animated)
    }

    func makePlaceholderViewController() -> UIViewController & PlaceholderViewControllerType {
        return PlaceholderViewController()
    }

}
