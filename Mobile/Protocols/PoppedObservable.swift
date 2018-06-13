//
//  PoppedObservable.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/10/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import RxSwift

protocol PoppedObservable: class {
    var wasPopped: Observable<Void> { get }
    //var wasPoppedSubject: PublishSubject<Void> { get }
    func viewWasPopped()
}
