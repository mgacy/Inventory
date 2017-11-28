//
//  AttachableViewModelType.swift
//  Mobile
//
//  Thomas Visser
//  [Reactive MVVM](http://www.thomasvisser.me/2017/02/09/mvvm-rx/)
//
//  Created by Mathew Gacy on 11/26/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation

protocol AttachableViewModelType {
    associatedtype Dependency
    associatedtype Bindings

    init(dependency: Dependency, bindings: Bindings)
}

enum Attachable<VM: AttachableViewModelType> {

    case detached(VM.Dependency)
    case attached(VM.Dependency, VM)

    mutating func bind(_ bindings: VM.Bindings) -> VM {
        switch self {
        case let .detached(dependency):
            let vm = VM(dependency: dependency, bindings: bindings)
            self = .attached(dependency, vm)
            return vm
        case let .attached(dependency, _):
            let vm = VM(dependency: dependency, bindings: bindings)
            self = .attached(dependency, vm)
            return vm
        }
    }

}
