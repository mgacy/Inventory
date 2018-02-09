//
//  PrimaryContainerType.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/8/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit

//protocol DetailViewControllerType where Self: UIViewController {}

enum DetailView<T: UIViewController> {
    case visible(T)
    case empty
}

protocol PrimaryContainerType: class {
    var detailView: DetailView<UIViewController> { get set }
    func collapseDetail()
    func separateDetail()
    func makeEmptyViewController() -> UIViewController
}
