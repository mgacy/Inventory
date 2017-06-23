//
//  Dynamic.swift
//  MVVMExample
//
//  Created by Dino Bartosak on 25/09/16.
//  Copyright © 2016 Toptal. All rights reserved.
//

// https://www.toptal.com/ios/swift-tutorial-introduction-to-mvvm

class Dynamic<T> {
    // swiftlint:disable:next void_return
    typealias Listener = (T) -> ()
    var listener: Listener?

    func bind(_ listener: Listener?) {
        self.listener = listener
    }

    func bindAndFire(_ listener: Listener?) {
        self.listener = listener
        listener?(value)
    }

    var value: T {
        didSet {
            listener?(value)
        }
    }

    init(_ val: T) {
        value = val
    }
}
