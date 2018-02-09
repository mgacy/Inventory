//
//  HomeViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/7/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import PKHUD
import RxCocoa
import RxSwift

class HomeViewController: UIViewController, AttachableType {

    private enum Strings {
        /// TODO: navTitle should be store name
        static let navTitle = "Home"
        static let errorAlertTitle = "Error"
        static let newOrderTitle = "Create Order"
        static let newOrderMessage = "Set order quantities from the most recent inventory or simply use pars?"
    }

    // MARK: - Alert
    private enum GenerationMethod: CustomStringConvertible {
        case count
        case par
        case cancel

        var description: String {
            switch self {
            case .count:
                return "From Count"
            case .par:
                return "From Par"
            case .cancel:
                return "Cancel"
            }
        }

        var method: NewOrderGenerationMethod {
            switch self {
            case .count:
                return NewOrderGenerationMethod.count
            case .par:
                return NewOrderGenerationMethod.par
            default:
                return NewOrderGenerationMethod.par
            }
        }
    }

    // MARK: - Properties

    var bindings: HomeViewModel.Bindings {
        return HomeViewModel.Bindings(
            addInventoryTaps: addInventoryButton.rx.tap.asObservable(),
            // FIXME: is this safe?
            addOrderTaps: addOrderButton.rx.tap.flatMap { [unowned self] _ in return self.mapAlert() }
        )
    }
    var viewModel: HomeViewModel!
    let disposeBag = DisposeBag()

    // MARK: - Interface
    let settingsButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Settings"), style: .plain, target: nil, action: nil)

    @IBOutlet weak var addInventoryButton: UIButton!
    @IBOutlet weak var addOrderButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        //title = Strings.navTitle
        self.navigationItem.leftBarButtonItem = settingsButtonItem
        //self.navigationItem.rightBarButtonItem =
    }

    //private func setupConstraints() {}

    func bindViewModel() {
        viewModel.storeName
            .drive(self.rx.title)
            .disposed(by: disposeBag)

        viewModel.isLoading
            .drive(onNext: { status in
                switch status {
                case true:
                    HUD.show(.progress)
                case false:
                    HUD.hide()
                }
            })
            .disposed(by: disposeBag)

        viewModel.errorMessages
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)
    }

    private func mapAlert() -> Observable<NewOrderGenerationMethod> {
        let actions: [GenerationMethod] = [.count, .par]
        return promptFor(title: Strings.newOrderTitle, message: Strings.newOrderMessage, cancelAction: .cancel,
                         actions: actions)
            .filter { $0 != .cancel }
            .map { $0.method }
    }

}
