//
//  AttachableType.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/27/17.
//
//  Modelled after `BindableType.swift`
//  RxSwift: Reactive Programming with Swift
//  Copyright (c) 2016 Razeware LLC
//

import UIKit
import RxSwift

// TODO: rename ViewModelAttaching?
protocol AttachableType: class {
    associatedtype ViewModel: AttachableViewModelType

    var bindings: ViewModel.Bindings { get }
    var viewModel: Attachable<ViewModel>! { get set }

    func attach(wrapper: Attachable<ViewModel>) -> ViewModel
    func bind(viewModel: ViewModel) -> ViewModel
}

extension AttachableType where Self: UIViewController {

    @discardableResult
    func attach(wrapper: Attachable<ViewModel>) -> ViewModel {
        viewModel = wrapper
        loadViewIfNeeded()
        let vm = viewModel.bind(bindings)
        return bind(viewModel: vm)
    }

}
