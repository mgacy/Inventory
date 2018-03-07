//
//  AttachableType.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/27/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//
//  Modelled after `BindableType.swift`
//  RxSwift: Reactive Programming with Swift
//  Copyright (c) 2016 Razeware LLC
//

import UIKit
import RxSwift

/// TODO: rename ViewModelAttaching?
protocol AttachableType: class {
    associatedtype ViewModel: AttachableViewModelType

    var bindings: ViewModel.Bindings { get }
    var viewModel: ViewModel! { get set }

    func bindViewModel()
}

extension AttachableType where Self: UIViewController {
    func bindViewModel<T>(to model: inout Attachable<T>) where T == Self.ViewModel {
        loadViewIfNeeded()
        viewModel = model.bind(bindings)
        bindViewModel()
        //return viewModel
    }
}
