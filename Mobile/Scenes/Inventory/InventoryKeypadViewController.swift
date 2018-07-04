//
//  InventoryKeypadViewController.swift
//  Playground
//
//  Created by Mathew Gacy on 10/10/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class InventoryKeypadViewController: UIViewController {

    // MARK: Properties

    var viewModel: InventoryKeypadViewModel!
    let disposeBag = DisposeBag()

    // swiftlint:disable:next weak_delegate
    private let customTransitionDelegate = SheetTransitioningDelegate()
    private let changeItemDissmissalEvent = PublishSubject<DismissalEvent>()
    private let panGestureDissmissalEvent = PublishSubject<DismissalEvent>()

    // Pan down transitions back to the presenting view controller
    var interactionController: UIPercentDrivenInteractiveTransition?

    let panGestureRecognizer: UIPanGestureRecognizer

    var dismissalEvents: Observable<DismissalEvent> {
        return Observable.never()
    }

    // MARK: View

    lazy var displayView: InventoryKeypadDisplayView = {
        let view = InventoryKeypadDisplayView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var keypadView: KeypadView = {
        let view = KeypadView()
        view.viewController = self
        view.backgroundColor = ColorPalette.lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [displayView, keypadView])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fill
        view.spacing = 0.0
        return view
    }()

    // MARK: - Lifecycle

    init() {
        panGestureRecognizer = UIPanGestureRecognizer()
        super.init(nibName: nil, bundle: nil)
        panGestureRecognizer.addTarget(self, action: #selector(handleGesture(_:)))
        modalPresentationStyle = .custom
        transitioningDelegate = customTransitionDelegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    //override func viewWillAppear(_ animated: Bool) {}

    // MARK: - View Methods

    private func setupView() {
        // Handle swipe down gesture
        //let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)

        view.addSubview(stackView)
        setupConstraints()

        setupBindings()
        setupKeypad()
    }

    func setupBindings() {
        // itemDisplayView
        viewModel.itemName
            .asObservable()
            .bind(to: displayView.itemDisplayView.rx.itemName)
            .disposed(by: disposeBag)

        viewModel.itemPack
            .asObservable()
            .bind(to: displayView.itemDisplayView.rx.itemPack)
            .disposed(by: disposeBag)

        // inventoryDisplayView
        viewModel.itemValue
            .asObservable()
            .bind(to: displayView.inventoryDisplayView.itemValueLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.itemHistory
            .asObservable()
            .bind(to: displayView.inventoryDisplayView.itemHistoryLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.itemUnit
            .asObservable()
            .bind(to: displayView.inventoryDisplayView.itemUnitLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.itemValueColor
            .asObservable()
            .subscribe(onNext: {[weak self] color in
                self?.displayView.inventoryDisplayView.itemValueLabel.textColor = color
            })
            .disposed(by: disposeBag)
    }

    private func setupConstraints() {
        //let guide: UILayoutGuide
        //if #available(iOS 11, *) {
        //    guide = view.safeAreaLayoutGuide
        //} else {
        //    guide = view.layoutMarginsGuide
        //}
        let constraints = [
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            keypadView.heightAnchor.constraint(equalTo: displayView.heightAnchor, multiplier: 1.5)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func setupKeypad() {
        keypadView.softButton1.setTitle("+1", for: .normal)
        keypadView.softButton2.setTitle("+", for: .normal)
    }

    // MARK: - Keypad

    @objc func numberTapped(sender: UIButton) {
        guard let title = sender.currentTitle, let number = Int(title) else { return }
        viewModel.pushDigit(value: number)
    }

    @objc func clearTapped(sender: UIButton) {
        viewModel.popItem()
    }

    @objc func decimalTapped(_ sender: UIButton) {
        viewModel.pushDecimal()
    }

    // MARK: - Uncertain

    @objc func softButton1Tapped(sender: UIButton) {
        viewModel.pushOperator()
        viewModel.pushDigit(value: 1)
        viewModel.pushOperator()
    }

    @objc func softButton2Tapped(sender: UIButton) {
        viewModel.pushOperator()
    }

    // MARK: - Item Navigation

    @objc func nextItemTapped(_ sender: UIButton) {
        switch viewModel.nextItem() {
        case true:
            return
        case false:
            changeItemDissmissalEvent.onNext(.wasDismissed)
            /// TODO: emit event so coordinator can dismiss
            if let navController = navigationController {
                navController.popViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
        }
    }

    @objc func previousItemTapped(_ sender: UIButton) {
        switch viewModel.previousItem() {
        case true:
            return
        case false:
            changeItemDissmissalEvent.onNext(.wasDismissed)
            /// TODO: emit event so coordinator can dismiss
            if let navController = navigationController {
                navController.popViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
        }
    }

    // MARK: - B

    @objc func handleGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        let percent = translation.y / gesture.view!.bounds.size.height
        //log.debug("%: \(percent)")
        switch gesture.state {
        case .began:
            interactionController = UIPercentDrivenInteractiveTransition()
            customTransitionDelegate.interactionController = interactionController
            dismiss(animated: true)
        case .changed:
            //log.debug("changed: \(percent)")
            interactionController?.update(percent)
        case .ended:
            let velocity = gesture.velocity(in: gesture.view)
            //log.debug("velocity: \(velocity)")
            interactionController?.completionSpeed = 0.999  // https://stackoverflow.com/a/42972283/1271826
            if (percent > 0.5 && velocity.y >= 0) || velocity.y > 0 {
                interactionController?.finish()
                /// Ensure we return event from coordinator when dismissing view with pan gesture
                panGestureDissmissalEvent.onNext(.wasDismissed)
            } else {
                interactionController?.cancel()
            }
            interactionController = nil
        default:
            if translation != .zero {
                let angle = atan2(translation.y, translation.x)
                log.debug("Angle: \(angle)")
            }
        }
    }

}

extension InventoryKeypadViewController: UIGestureRecognizerDelegate {

    // Recognize downward gestures only
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = pan.translation(in: pan.view)
            let angle = atan2(translation.y, translation.x)
            return abs(angle - .pi / 2.0) < (.pi / 8.0)
            // ALT
            //let angle = abs(atan2(translation.x, translation.y) - .pi / 2)
            //return angle < .pi / 8.0
        }
        return false
    }
}

extension InventoryKeypadViewController: KeypadViewControllerType {}

extension InventoryKeypadViewController: ModalKeypadDismissing {}
