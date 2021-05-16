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
        let firstName: Observable<String>
        let lastName: Observable<String>
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
            input.firstName, input.lastName, input.login, input.password
        ) { (firstName, lastName, login, password) -> (String, String, String, String) in
            return (firstName, lastName, login, password)
        }

        let isValid = userInputs
            .map { firstName, lastName, login, password in
                return firstName.count > 0 && lastName.count > 0  && login.count > 0 && password.count > 0
            }

        let signingUp = ActivityIndicator()
        let signupResults = Observable.of(input.signupTaps, input.doneTaps)
            .merge()
            .withLatestFrom(userInputs)
            .flatMap { (arg) -> Observable<Event<Bool>> in
                let (firstName, lastName, email, password) = arg
                return self.dataManager.signUp(firstName: firstName, lastName: lastName, email: email,
                                               password: password)
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
