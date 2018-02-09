//
//  ViewModelType.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/14/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//
//  Martin Moizard
//  https://medium.com/blablacar-tech/rxswift-mvvm-66827b8b3f10
//

import Foundation

protocol ViewModelType {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}
