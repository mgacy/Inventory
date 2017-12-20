//
//  SignUpViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/23/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxCocoa
import RxSwift

final class SignUpViewModel: ViewModelType {

    struct Input {
        let username: Observable<String>
        let login: Observable<String>
        let password: Observable<String>
        //let cancelTaps: Observable<Void>
        let signupTaps: Observable<Void>
        let doneTaps: Observable<Void>
    }

    struct Output {
        //let didCancel: Observable<Void>
        let isValid: Observable<Bool>
        let signingUp: Driver<Bool>
        let signupResults: Observable<Event<Bool>>
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

        let signingUp = ActivityIndicator()
        let signupResults = Observable.of(input.signupTaps, input.doneTaps)
            .merge()
            .withLatestFrom(userInputs)
            .flatMap { (arg) -> Observable<Event<Bool>> in
                let (email, password) = arg
                return self.dataManager.signUp(username: email, email: email, password: password)
                    .trackActivity(signingUp)
            }
            .share(replay: 1)

        return Output(
            //didCancel: input.cancelTaps,
            isValid: isValid,
            signingUp: signingUp.asDriver(),
            signupResults: signupResults
        )
    }

}
