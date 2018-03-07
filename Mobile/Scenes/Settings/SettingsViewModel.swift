//
//  SettingsViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxCocoa
import RxSwift

final class SettingsViewModel: AttachableViewModelType {

    let accountCellText: Driver<String>
    let didLogout: Driver<Bool>
    let showLogin: Driver<Void>

    // MARK: - Lifecycle

    init(dependency: Dependency, bindings: Bindings) {

        accountCellText = dependency.userManager.currentUser
            .map { user in
                return user != nil ? "Logout \(user!.email)" : "Login"
            }
            .asDriver(onErrorJustReturn: "Error")

        let accountCellTaps = bindings.selection
            .filter { $0.section == 0 }

        didLogout = accountCellTaps
            .filter { _ in dependency.userManager.authenticationState == .signedIn }
            .flatMap { _ in
                /// TODO: check for pending Inventory / Invoice / Order
                /// TODO: if so, present warning; this should be handled by using `.materialize()` in dataManager
                return dependency.dataManager.logout()
                    .asDriver(onErrorJustReturn: false)
            }

        showLogin = accountCellTaps
            .filter { _ in dependency.userManager.authenticationState == .signedOut }
            .map { _ in return }
    }

    // MARK: - ViewModelType

    typealias Dependency = HasDataManager & HasUserManager

    struct Bindings {
        let selection: Driver<IndexPath>
    }

}
