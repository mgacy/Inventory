//
//  Observable+Extensions.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/8/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//
//  From:
//  https://github.com/sergdort/CleanArchitectureRxSwift
//  Copyright (c) 2017 Sergey Shulga
//

import RxSwift
import RxCocoa

// swiftlint:disable unused_closure_parameter

extension ObservableType where E == Bool {
    /// Boolean not operator
    public func not() -> Observable<Bool> {
        return self.map(!)
    }
}

extension SharedSequenceConvertibleType {
    func mapToVoid() -> SharedSequence<SharingStrategy, Void> {
        return map { _ in }
    }
}

extension ObservableType {

    func catchErrorJustComplete() -> Observable<E> {
        return catchError { _ in
            return Observable.empty()
        }
    }

    func asDriverOnErrorJustComplete() -> Driver<E> {
        return asDriver { error in
            return Driver.empty()
        }
    }

    func mapToVoid() -> Observable<Void> {
        return map { _ in }
    }
}
