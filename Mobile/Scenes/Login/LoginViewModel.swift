//
//  LoginViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxCocoa
import RxSwift

final class LoginViewModel: ViewModelType {

    struct Input {
        let username: Observable<String>
        let password: Observable<String>
        let loginTaps: Observable<Void>
        let doneTaps: Observable<Void>
        //let signupTaps: Observable<Void>
    }

    struct Output {
        let currentUser: Observable<RemoteUser?>
        let isValid: Observable<Bool>
        let loggingIn: Driver<Bool>
        let loginResults: Observable<Event<Bool>>
        //let didSignup: Observable<Void>
    }

    // MARK: Dependencies
    private let dataManager: DataManager

    // MARK: - Lifecycle

    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }

    func transform(input: Input) -> Output {
        let userInputs = Observable.combineLatest(
            input.username, input.password
        ) { (login, password) -> (String, String) in
            return (login, password)
        }

        let isValid = userInputs
            .map { username, password in
                //return !username.isEmpty && !password.isEmpty
                return username.count > 0 && password.count > 0
            }

        let loggingIn = ActivityIndicator()

        let loginResults = Observable.of(input.loginTaps, input.doneTaps)
            .merge()
            .withLatestFrom(userInputs)
            .flatMap { (arg) -> Observable<Event<Bool>> in
                let (email, password) = arg
                return self.dataManager.login(email: email, password: password)
                    .trackActivity(loggingIn)
            }
            .share(replay: 1)

        return Output(
            currentUser: dataManager.userManager.currentUser,
            isValid: isValid,
            loggingIn: loggingIn.asDriver(),
            loginResults: loginResults
        )
    }

}
