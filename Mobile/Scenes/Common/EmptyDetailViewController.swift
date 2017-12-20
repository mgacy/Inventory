//
//  EmptyDetailViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/12/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

class EmptyDetailViewController: UIViewController {

    let backgroundImageView: UIImageView = {
        let view = UIImageView()
        view.image = #imageLiteral(resourceName: "Logo")
        view.tintColor = .gray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
    }

    func setupView() {
        self.view.backgroundColor = ColorPalette.lightGray
        self.view.addSubview(backgroundImageView)
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
    }

    func setupConstraints() {
        backgroundImageView.widthAnchor.constraint(equalToConstant: 180.0).isActive = true
        backgroundImageView.heightAnchor.constraint(equalToConstant: 180.0).isActive = true
        backgroundImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        backgroundImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

}
