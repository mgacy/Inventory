//
//  OrderKeypadViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class OrderKeypadViewController: UIViewController {
    typealias KeypadViewModelType = OrderKeypadViewModelType & KeypadProxy & DisplayItemViewModelType

    // MARK: - Properties

    let disposeBag = DisposeBag()
    //let dismissalEvents: Observable<Void>
    var viewModel: KeypadViewModelType!

    // swiftlint:disable:next weak_delegate
    private let customTransitionDelegate = SheetTransitioningDelegate()
    private let changeItemDissmissalEvent = PublishSubject<Void>()
    private let panGestureDissmissalEvent = PublishSubject<Void>()

    // Pan down transitions back to the presenting view controller
    var interactionController: UIPercentDrivenInteractiveTransition?

    let panGestureRecognizer: UIPanGestureRecognizer

    var dismissalEvents: Observable<Void> {
        return Observable.of(
            displayView.dismissalEvents.asObservable(),
            changeItemDissmissalEvent.asObservable(),
            panGestureDissmissalEvent.asObservable()
        )
        .merge()
    }

    // MARK: View

    lazy var displayView: OrderKeypadDisplayView = {
        let view = OrderKeypadDisplayView()
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
        //self.dismissalEvents = Observable.of(
        //    //displayView.dismissalEvents.asObservable(),
        //    panGestureDissmissalEvent.asObservable()
        //).merge()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplay()
    }

    //override func didReceiveMemoryWarning() {}

    deinit { log.debug("\(#function)") }

    // MARK: - View Methods

    private func setupView() {
        // Handle swipe down gesture
        //let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)

        view.addSubview(stackView)
        setupConstraints()
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

    // MARK: - Keypad

    @objc func numberTapped(sender: UIButton) {
        guard let title = sender.currentTitle, let number = Int(title) else { return }
        viewModel.pushDigit(value: number)
        updateDisplay()
        //order.text = viewModel.orderQuantity
    }

    @objc func clearTapped(sender: UIButton) {
        viewModel.popItem()
        updateDisplay()
        //order.text = viewModel.orderQuantity
    }

    @objc func decimalTapped(_ sender: UIButton) {
        viewModel.pushDecimal()
        updateDisplay()
        //order.text = viewModel.orderQuantity
    }

    // MARK: Units

    /// Pack Button
    @objc func softButton1Tapped(sender: UIButton) {
        guard viewModel.switchUnit(.packUnit) == true else {
            return
        }
        updateDisplay()
    }

    /// Unit Button
    @objc func softButton2Tapped(sender: UIButton) {
        guard viewModel.switchUnit(.singleUnit) == true else {
            return
        }
        updateDisplay()
    }

    // MARK: Item Navigation

    @objc func nextItemTapped(_ sender: UIButton) {
        switch viewModel.nextItem() {
        case true:
            updateDisplay()
        case false:
            changeItemDissmissalEvent.onNext(())
            //if let navController = navigationController {
            //    navController.popViewController(animated: true)
            //} else {
            //    dismiss(animated: true)
            //}
        }
    }

    @objc func previousItemTapped(_ sender: UIButton) {
        switch viewModel.previousItem() {
        case true:
            updateDisplay()
        case false:
            changeItemDissmissalEvent.onNext(())
            //if let navController = navigationController {
            //    navController.popViewController(animated: true)
            //} else {
            //    dismiss(animated: true)
            //}
        }
    }

    // MARK: - Display

    func updateDisplay(animated: Bool = true) {
        displayView.bind(to: viewModel)
        updateKeypad()
    }

    /// TODO: rename `updateUnitButtons`?
    func updateKeypad(animated: Bool = true) {
        keypadView.softButton1.setTitle(viewModel.packUnitLabel, for: .normal)
        keypadView.softButton1.isEnabled = viewModel.singleUnitIsEnabled

        keypadView.softButton2.setTitle(viewModel.singleUnitLabel, for: .normal)
        keypadView.softButton2.isEnabled = viewModel.packUnitIsEnabled

        guard let currentUnit = viewModel.currentUnit else {
            keypadView.softButton1.backgroundColor = ColorPalette.secondary
            keypadView.softButton2.backgroundColor = ColorPalette.secondary
            return
        }

        switch currentUnit {
        case .singleUnit:
            keypadView.softButton1.backgroundColor = ColorPalette.secondary
            keypadView.softButton2.backgroundColor = ColorPalette.navy
        case .packUnit:
            keypadView.softButton1.backgroundColor = ColorPalette.navy
            keypadView.softButton2.backgroundColor = ColorPalette.secondary
        case .invalidUnit:
            keypadView.softButton1.backgroundColor = ColorPalette.secondary
            keypadView.softButton2.backgroundColor = ColorPalette.secondary
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
                panGestureDissmissalEvent.onNext(())
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

extension OrderKeypadViewController: UIGestureRecognizerDelegate {

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

extension OrderKeypadViewController: KeypadViewControllerType {}

extension OrderKeypadViewController: ModalKeypadDismissing {}
