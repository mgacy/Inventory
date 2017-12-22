//
//  AttachableType.swift
//  Mobile
//
//  Modelled after `BindableType.swift`
//  RxSwift: Reactive Programming with Swift
//  Copyright (c) 2016 Razeware LLC
//
//  Created by Mathew Gacy on 11/27/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import RxSwift

/// TODO: rename ViewModelAttaching?
protocol AttachableType {
    associatedtype ViewModel: AttachableViewModelType
    associatedtype Bindings

    var bindings: Bindings { get }
    var viewModel: ViewModel! { get set }

    func bindViewModel()
}

extension AttachableType where Self: UIViewController {
    mutating func bindViewModel<T>(to model: inout Attachable<T>) where T == Self.ViewModel, T.Bindings == Self.Bindings {
        loadViewIfNeeded()
        viewModel = model.bind(bindings)
        bindViewModel()
        //return viewModel
    }
}
