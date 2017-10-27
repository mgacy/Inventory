//
//  InitialLoginViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxCocoa
import RxSwift

struct InitialLoginViewModel {

    // MARK: - Properties

    //private let dataManager: DataManager
    let dataManager: DataManager

    // MARK: - Input
    let username = Variable<String>("")
    let password = Variable<String>("")
    let loginTaps: AnyObserver<Void>
    let signupTaps: AnyObserver<Void>

    // MARK: - Output
    var currentUser: User? { return dataManager.userManager.user }
    let isValid: Observable<Bool>
    let loggingIn: Driver<Bool>
    let loginResults: Observable<Event<Bool>>
    let didSignup: Observable<Void>

    // MARK: - Lifecycle

    init(dataManager: DataManager) {
        self.dataManager = dataManager

        let _login = PublishSubject<Void>()
        self.loginTaps = _login.asObserver()

        let _signup = PublishSubject<Void>()
        self.signupTaps = _signup.asObserver()
        self.didSignup = _signup.asObservable()

        let userInputs = Observable.combineLatest(
            username.asObservable(), password.asObservable()
        ) { (login, password) -> (String, String) in
            return (login, password)
        }

        isValid = userInputs
            .map { username, password in
                //return !username.isEmpty && !password.isEmpty
                return username.count > 0 && password.count > 0
        }

        let loggingIn = ActivityIndicator()
        self.loggingIn = loggingIn.asDriver()

        self.loginResults = _login.asObservable()
            .withLatestFrom(userInputs)
            .flatMap { (arg) -> Observable<Event<Bool>> in
            //.map { (arg) in
                let (email, password) = arg
                return dataManager.login(email: email, password: password)
                    .trackActivity(loggingIn)
            }
            .share(replay: 1)
            //.shareReplay(1)
    }

}
