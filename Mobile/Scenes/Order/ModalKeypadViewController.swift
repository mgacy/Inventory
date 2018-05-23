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

/// TODO: define protocol specifying any dimensions required for constraints:
// - width of detailview controller
// - height of navbar?
protocol ModalKeypadPresenting: class {
    var frame: CGRect { get }
}

protocol ModalKeypadDismissing: class {
    var dismissalEvents: Observable<Void> { get }
}

final class ModalKeypadViewController: UIViewController {

    let disposeBag = DisposeBag()
    // swiftlint:disable:next weak_delegate
    private let customTransitionDelegate = SheetTransitioningDelegate()
    private let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: nil)
    private let panGestureDissmissalEvent = PublishSubject<Void>()

    // Pan down transitions back to the presenting view controller
    var interactionController: UIPercentDrivenInteractiveTransition?

    var dismissalEvents: Observable<Void> {
        return Observable.of(
            panGestureDissmissalEvent.asObservable(),
            barView.dismissChevron.rx.tap.mapToVoid(),
            tapGestureRecognizer.rx.event.mapToVoid()
        )
            .merge()
    }

    // MARK: Subviews
    private let keypadViewController: UIViewController & ModalKeypadDismissing
    private lazy var barView: ModalOrderBarView = {
        let view = ModalOrderBarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
        return view
    }()

    // MARK: - Lifecycle

    /// TODO: pass primary view controller (or its constraints) to configure widths?
    init(keypadViewController: UIViewController & ModalKeypadDismissing) {
        self.keypadViewController = keypadViewController
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

        view.addSubview(barView)
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
            // barView
            barView.topAnchor.constraint(equalTo: view.topAnchor),
            /// TODO: is this the best way to set the height?
            barView.heightAnchor.constraint(equalToConstant: 44),
            barView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.62),
            barView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            // keypad
            keypadViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.62),
            keypadViewController.view.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            keypadViewController.view.topAnchor.constraint(equalTo: barView.bottomAnchor),
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
        //log.debug("%: \(percent)");
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

// MARK: - Navigation Bar-Like SubView

class ModalOrderBarView: UIView {

    var dismissChevron: ChevronButton = {
        let button = ChevronButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 38, height: 15))
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Methods

    private func setupView() {
        backgroundColor = .white
        addSubview(dismissChevron)
        setupConstraints()
    }

    private func setupConstraints() {
        /*
        let guide: UILayoutGuide
        if #available(iOS 11, *) {
            guide = safeAreaLayoutGuide
        } else {
            guide = layoutMarginsGuide
        }
        */
        let constraints = [
            dismissChevron.widthAnchor.constraint(equalToConstant: 38),
            dismissChevron.heightAnchor.constraint(equalToConstant: 15),
            dismissChevron.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
            dismissChevron.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0)
            //dismissChevron.topAnchor.constraint(equalTo: guide.topAnchor, constant: 10)
        ]
        NSLayoutConstraint.activate(constraints)
    }

}
