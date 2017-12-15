//
//  EmptyDetailViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/12/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

class EmptyDetailViewController: UIViewController {

    /// TODO: is there any need to do this?
    lazy var mainView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorPalette.lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // meh ...
        setupView()
        setupConstraints()
    }

    func setupView() {
        self.view.addSubview(mainView)
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
    }

    func setupConstraints() {
        mainView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        mainView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        mainView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        mainView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }

}
