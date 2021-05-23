//
//  ModalKeypadViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 4/17/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

// TODO: define protocol specifying any dimensions required for constraints:
// - width of detailview controller
// - height of navbar?
protocol ModalKeypadPresenting: class {
    var frame: CGRect { get }
}

enum DismissalEvent {
    case shouldDismiss
    case wasDismissed
}

protocol ModalKeypadDismissing: class {
    var dismissalEvents: Observable<DismissalEvent> { get }
}

final class ModalKeypadViewController: UIViewController {

    let dismissalEvents: Observable<DismissalEvent>
    let disposeBag = DisposeBag()
    // swiftlint:disable:next weak_delegate
    private let customTransitionDelegate = SheetTransitioningDelegate()
    private let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: nil)
    private let panGestureDissmissalEvent = PublishSubject<DismissalEvent>()

    // Pan down transitions back to the presenting view controller
    var interactionController: UIPercentDrivenInteractiveTransition?

    // MARK: Subviews
    private let keypadViewController: UIViewController & ModalKeypadDismissing

    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
        view.isUserInteractionEnabled = true
        return view
    }()

    // MARK: - Lifecycle

    // TODO: pass primary view controller (or its constraints) to configure widths?
    init(keypadViewController: UIViewController & ModalKeypadDismissing) {
        self.keypadViewController = keypadViewController
        self.dismissalEvents = Observable.of(
            keypadViewController.dismissalEvents,
            panGestureDissmissalEvent.asObservable(),
            tapGestureRecognizer.rx.event.map { _ in .shouldDismiss }
        )
        .merge()

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

    // MARK: - View Methods

    private func setupView() {
        view.backgroundColor = UIColor.clear
        view.isOpaque = false

        view.addSubview(backgroundView)
        backgroundView.addGestureRecognizer(tapGestureRecognizer)
        backgroundView.isUserInteractionEnabled = true

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        panGestureRecognizer.delegate = self
        keypadViewController.view.addGestureRecognizer(panGestureRecognizer)

        embedViewController()
    }

    private func embedViewController() {
        let guide: UILayoutGuide
        if #available(iOS 11, *) {
            guide = view.safeAreaLayoutGuide
        } else {
            guide = view.layoutMarginsGuide
        }

        let constraints = [
            // keypad
            keypadViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.62),
            keypadViewController.view.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            keypadViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            keypadViewController.view.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            // backgroundView
            backgroundView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: keypadViewController.view.leadingAnchor, constant: 0),
            backgroundView.topAnchor.constraint(equalTo: guide.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ]
        add(keypadViewController, with: constraints)
    }

    // MARK: - B

    @objc func handleGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        let percent = translation.y / gesture.view!.bounds.size.height
        //log.verbose("%: \(percent)");
        switch gesture.state {
        case .began:
            interactionController = UIPercentDrivenInteractiveTransition()
            customTransitionDelegate.interactionController = interactionController
            dismiss(animated: true)

            /// https://stackoverflow.com/a/50238562/4472195
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                self.interactionController?.update(percent)
            }
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

extension ModalKeypadViewController: UIGestureRecognizerDelegate {

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

extension ModalKeypadViewController: ModalKeypadDismissing {}
