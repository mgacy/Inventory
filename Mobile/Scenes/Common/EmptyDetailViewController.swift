//
//  EmptyDetailViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/12/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

class PlaceholderViewController: UIViewController, PlaceholderViewControllerType {

    let backgroundImageView: UIImageView = {
        let view = UIImageView()
        view.image = #imageLiteral(resourceName: "Logo")
        view.tintColor = ColorPalette.starDust
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        if let displayModeButtonItem = splitViewController?.displayModeButtonItem {
            navigationItem.leftBarButtonItem = displayModeButtonItem
        }
    }

    // MARK: - View Methods

    func setupView() {
        view.backgroundColor = ColorPalette.athensGray
        view.addSubview(backgroundImageView)
        navigationItem.leftItemsSupplementBackButton = true
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundImageView.widthAnchor.constraint(equalToConstant: 180.0),
            backgroundImageView.heightAnchor.constraint(equalToConstant: 180.0),
            backgroundImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backgroundImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

}
