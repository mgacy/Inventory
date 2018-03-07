//
//  Coordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/8/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import RxSwift

protocol Coordinator {
    associatedtype CoordinationResult
    var identifier: UUID { get }
    func start() -> Observable<CoordinationResult>
}
