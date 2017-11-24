//
//  HomeViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/7/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import PKHUD
import RxCocoa
import RxSwift

class HomeViewController: UIViewController {

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
        //setupConstraints()
        bindViewModel()
        //setupTableView()
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

    // swiftlint:disable:next function_body_length
    private func bindViewModel() {
        let inputs = HomeViewModel.Input(addInventoryTaps: addInventoryButton.rx.tap.asObservable(),
                                         addOrderTaps: addOrderButton.rx.tap
                                            // FIXME: is this safe?
                                            .flatMap { [unowned self] _ in return self.mapAlert() })
        let outputs = viewModel.transform(input: inputs)

        outputs.storeName
            .drive(onNext: { [weak self] name in
                self?.title = name
            })
            .disposed(by: disposeBag)

        outputs.isLoading
            .drive(onNext: { status in
                switch status {
                case true:
                    HUD.show(.progress)
                case false:
                    HUD.hide()
                }
            })
            .disposed(by: disposeBag)

        outputs.errorMessages
            .drive(onNext: { [weak self] message in
                self?.showAlert(title: Strings.errorAlertTitle, message: message)
            })
            .disposed(by: disposeBag)

        outputs.showInventory
            .drive(onNext: { [weak self] inventory in
                log.debug("Show Inventory view with: \(inventory)")
                guard let strongSelf = self else {
                    log.error("\(#function) FAILED : unable to get reference to self"); return
                }
                let vc = InventoryLocationViewController.initFromStoryboard(name: "InventoryLocationViewController")
                vc.viewModel = InventoryLocationViewModel(dataManager: strongSelf.viewModel.dataManager,
                                                          parentObject: inventory, rowTaps: vc.selectedIndices,
                                                          uploadTaps: vc.uploadButtonItem.rx.tap.asObservable())
                let navigationController = UINavigationController(rootViewController: vc)
                strongSelf.navigationController?.present(navigationController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)

        outputs.showOrder
            .subscribe(onNext: { [weak self] orderCollection in
                guard let strongSelf = self else {
                    log.error("\(#function) FAILED : unable to get reference to self"); return
                }
                let vc = OrderContainerViewController.initFromStoryboard(name: "OrderContainerViewController")
                vc.viewModel = OrderContainerViewModel(dataManager: strongSelf.viewModel.dataManager,
                                                       parentObject: orderCollection,
                                                       completeTaps: vc.completeButtonItem.rx.tap.asObservable())
                let navigationController = UINavigationController(rootViewController: vc)
                strongSelf.navigationController?.present(navigationController, animated: true, completion: nil)
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
