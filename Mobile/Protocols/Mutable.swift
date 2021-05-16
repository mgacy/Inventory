//
//  Mutable.swift
//  Mobile
//
//  Created by Mathew Gacy on 3/8/18.
//

import Foundation

// MARK: - Lenses

// From RxSwift
// `.../RxExample/RxExample/Lenses.swift`

// These are kind of "Swift" lenses. We don't need to generate a lot of code this way and can just use Swift `var`.
public protocol Mutable {}

public extension Mutable {
    func mutateOne<T>(transform: (inout Self) -> T) -> Self {
        var newSelf = self
        _ = transform(&newSelf)
        return newSelf
    }

    func mutate(transform: (inout Self) -> Void) -> Self {
        var newSelf = self
        transform(&newSelf)
        return newSelf
    }

    func mutate(transform: (inout Self) throws -> Void) rethrows -> Self {
        var newSelf = self
        try transform(&newSelf)
        return newSelf
    }
}
