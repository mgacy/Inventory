//
//  InitialSignUpViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/23/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxCocoa
import RxSwift

struct InitialSignUpViewModel {

    // MARK: - Properties

    //private let dataManager: DataManager
    let dataManager: DataManager

    // MARK: Inputs
    let username = Variable<String>("")
    let login = Variable<String>("")
    let password = Variable<String>("")
    let cancelTaps: AnyObserver<Void>
    let signupTaps: AnyObserver<Void>

    // MARK: Outputs
    let didCancel: Observable<Void>
    //let didSignup: Observable<Bool>
    let isValid: Observable<Bool>
    let signingUp: Driver<Bool>
    let signupResults: Observable<Event<Bool>>

    // MARK: - Lifecycle
    init(dataManager: DataManager) {
        self.dataManager = dataManager

        let _cancel = PublishSubject<Void>()
        self.cancelTaps = _cancel.asObserver()
        self.didCancel = _cancel.asObservable()

        let _signup = PublishSubject<Void>()
        self.signupTaps = _signup.asObserver()
        //self.didSignup = _signup.asObservable()

        let userInputs = Observable.combineLatest(
            username.asObservable(), password.asObservable()
        ) { (login, password) -> (String, String) in
            return (login, password)
        }

        isValid = userInputs
            .map { username, password in
                return username.characters.count > 0 && password.characters.count > 0
        }

        // Signup

        let signingUp = ActivityIndicator()
        self.signingUp = signingUp.asDriver()

        self.signupResults = _signup.asObservable()
            .withLatestFrom(userInputs)
            .flatMap { (arg) -> Observable<Event<Bool>> in
                let (email, password) = arg
                return dataManager.signUp(username: email, email: email, password: password)
                    .trackActivity(signingUp)
            }
            .shareReplay(1)
    }

}
