//
//  SettingsViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxCocoa
import RxSwift

struct SettingsViewModel {

    // MARK: - Properties

    private let dataManager: DataManager

    // MARK: Inputs
    //let accountCellTaps: AnyObserver<Void>

    // MARK: Outputs
    var currentUser: User? { return dataManager.userManager.user }
    //let accountCellText: Driver<String>
    let didLogout: Driver<Bool>
    //let showLogin: Driver<Void>
    let showLogin: Observable<Void>

    // MARK: - Lifecycle
    init(dataManager: DataManager, rowTaps: Observable<IndexPath>) {
        self.dataManager = dataManager

        let accountCellTaps = rowTaps
            .filter { $0.section == 0 }
            .share()

        didLogout = accountCellTaps
            .filter { _ in dataManager.userManager.user != nil }
            .flatMap { _ in
                /// TODO: check for pending Inventory / Invoice / Order
                /// TODO: if so, present warning; this should be handled by using `.materialize()` in dataManager
                return dataManager.logout()
            }
            .asDriver(onErrorJustReturn: false)

        showLogin = accountCellTaps
            .filter { _ in dataManager.userManager.user == nil }
            .map { _ in return }
            //.asDriver(onErrorJustReturn: ())
    }

}
