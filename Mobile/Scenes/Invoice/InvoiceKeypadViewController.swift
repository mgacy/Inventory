//
//  InvoiceKeypadViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

final class InvoiceKeypadViewController: UIViewController {

    // MARK: - Properties

    let disposeBag = DisposeBag()
    var viewModel: InvoiceKeypadViewModel!

    // swiftlint:disable:next weak_delegate
    private let customTransitionDelegate = SheetTransitioningDelegate()
    private let changeItemDissmissalEvent = PublishSubject<DismissalEvent>()
    private let panGestureDissmissalEvent = PublishSubject<DismissalEvent>()

    // Pan down transitions back to the presenting view controller
    var interactionController: UIPercentDrivenInteractiveTransition?

    var dismissalEvents: Observable<DismissalEvent> {
        return Observable.of(
            displayView.dismissalEvents.asObservable(),
            changeItemDissmissalEvent.asObservable(),
            panGestureDissmissalEvent.asObservable()
        )
        .merge()
    }

    // MARK: View

    lazy var displayView: InvoiceKeypadDisplayView = {
        let view = InvoiceKeypadDisplayView()
        view.invoiceDisplayView.viewController = self
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
        super.init(nibName: nil, bundle: nil)
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

    // MARK: - View Methods

    private func setupView() {
        // Handle swipe down gesture
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
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
        //if viewModel.currentMode == .status { return }
        viewModel.pushDigit(value: number)
        updateDisplay()
    }

    @objc func clearTapped(sender: UIButton) {
        viewModel.popItem()
        updateDisplay()
    }

    @objc func decimalTapped(_ sender: UIButton) {
        viewModel.pushDecimal()
        updateDisplay()
    }

    // MARK: Units

    @objc func softButton1Tapped(sender: UIButton) {
        switch viewModel.currentMode {
        // Toggle currentItem.unit
        case .quantity:
            log.verbose("currentMode: quantity")
            if viewModel.toggleUnit() {
                updateDisplay()
                keypadView.softButton1.setTitle(viewModel.unitButtonTitle, for: .normal)
            } else {
                log.error("\(#function) FAILED: unable to update InvoiceItem Unit")
            }
        // ?
        case .cost:
            log.verbose("currentMode: \(viewModel.currentMode)")
        // ?
        case .status:
            log.verbose("currentMode: \(viewModel.currentMode)")
            /*
            if var status = InvoiceItemStatus(rawValue: currentItem.status) {
                status.next()
                currentItem.status = status.rawValue
                //status.next()
                //softButton.setTitle(status.shortDescription, for: .normal)

            }
            softButton.setTitle("s", for: .normal)
            update()
             */
        }
    }

    @objc func softButton2Tapped(sender: UIButton) {
        return
    }

    // MARK: Item Navigation

    @objc func nextItemTapped(_ sender: UIButton) {
        switch viewModel.nextItem() {
        case true:
            updateDisplay()
        case false:
            changeItemDissmissalEvent.onNext(.shouldDismiss)
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
            changeItemDissmissalEvent.onNext(.shouldDismiss)
            //if let navController = navigationController {
            //    navController.popViewController(animated: true)
            //} else {
            //    dismiss(animated: true)
            //}
        }
    }

    // MARK: Mode

    func switchMode(to newMode: InvoiceKeypadViewModel.KeypadState) {
        viewModel.switchMode(newMode)
        updateDisplay()
    }

    // MARK: - Display

    func updateDisplay() {
        displayView.bind(to: viewModel)
        updateDisplayForCurrentMode()
    }

    func updateDisplayForCurrentMode() {
        switch viewModel.currentMode {
        case .cost:
            print("cost")
            keypadView.softButton1.setTitle("", for: .normal)
            keypadView.softButton1.isEnabled = false
        case .quantity:
            print("quantity")
            keypadView.softButton1.setTitle(viewModel.unitButtonTitle, for: .normal)
            // TODO: only enable if we are able to choose an alternate unit for CurrentItem?
            keypadView.softButton1.isEnabled = true
            /*
            // Should inactiveUnit simply return currentItem.unit instead of nil?
            if let altUnit = inactiveUnit {
                softButton1.setTitle(altUnit.abbreviation, for: .normal)
                softButton1.isEnabled = true
            } else {
                softButton1.setTitle(currentItem.unit?.abbreviation, for: .normal)
                softButton1.isEnabled = false
            }
             */
        case .status:
            print("status")
            keypadView.softButton1.setTitle("", for: .normal)
            keypadView.softButton1.isEnabled = true
        }
    }

    // MARK: - B

    @objc func handleGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        let percent = translation.y / gesture.view!.bounds.size.height
        //log.verbose("%: \(percent)")
        switch gesture.state {
        case .began:
            interactionController = UIPercentDrivenInteractiveTransition()
            customTransitionDelegate.interactionController = interactionController
            dismiss(animated: true)
        case .changed:
            //log.verbose("changed: \(percent)")
            interactionController?.update(percent)
        case .ended:
            let velocity = gesture.velocity(in: gesture.view)
            //log.verbose("velocity: \(velocity)")
            interactionController?.completionSpeed = 0.999  // https://stackoverflow.com/a/42972283/1271826
            if (percent > 0.5 && velocity.y >= 0) || velocity.y > 0 {
                interactionController?.finish()
                // Ensure we return event from coordinator when dismissing view with pan gesture
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

extension InvoiceKeypadViewController: UIGestureRecognizerDelegate {

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

extension InvoiceKeypadViewController: KeypadViewControllerType {}

extension InvoiceKeypadViewController: ModalKeypadDismissing {}
