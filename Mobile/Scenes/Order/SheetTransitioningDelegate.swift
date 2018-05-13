//
//  SheetTransitioningDelegate.swift
//  Mobile
//
//  Created by Mathew Gacy on 4/19/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit
//import RxSwift
//import RxCocoa

// MARK: - Transitioning Delegate

// [Rob](https://stackoverflow.com/users/1271826/rob)
// https://stackoverflow.com/a/42213998/4472195
class SheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    /// Interaction controller
    ///
    /// If gesture triggers transition, it will set its own `UIPercentDrivenInteractiveTransition`,
    /// but it must also set this reference to that interaction controller here, so that this knows
    /// whether it's interactive or not.

    weak var interactionController: UIPercentDrivenInteractiveTransition?

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return KeypadSheetAnimationController(transitionType: .presenting)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return KeypadSheetAnimationController(transitionType: .dismissing)
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return SheetPresentationController(presentedViewController: presented, presenting: presenting)
    }

    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }

}

// MARK: - Animation Controller

class KeypadSheetAnimationController: NSObject, UIViewControllerAnimatedTransitioning {

    enum TransitionType {
        case presenting
        case dismissing
    }

    let transitionType: TransitionType

    init(transitionType: TransitionType) {
        self.transitionType = transitionType
        super.init()
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
                return
        }
        switch transitionType {
        case .presenting:
            animatePresentation(from: fromVC, to: toVC, using: transitionContext)
        case .dismissing:
            animateDismissal(from: fromVC, to: toVC, using: transitionContext)
        }
    }

    // MARK: - Present / Dismiss

    private func animatePresentation(from fromVC: UIViewController, to toVC: UIViewController, using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let dy = containerView.frame.size.height
        let finalFrame = transitionContext.finalFrame(for: toVC)

        log.debug("\(#function): \(fromVC) -> \(toVC) in \(containerView)")

        /*
        guard let svc = fromVC as? UISplitViewController else {
            log.error("Cast failed: \(fromVC)")
            return
        }
        let width = containerView.frame.size.width - svc.primaryColumnWidth
        */
        toVC.view.frame = finalFrame.offsetBy(dx: 0.0, dy: dy)
        containerView.addSubview(toVC.view)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext), delay: 0,
            options: [ UIViewAnimationOptions.curveEaseOut ],
            animations: {
                toVC.view.frame = finalFrame
            },
            completion: { _ in transitionContext.completeTransition(!transitionContext.transitionWasCancelled) }
        )
    }

    private func animateDismissal(from fromVC: UIViewController, to toVC: UIViewController, using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let dy = containerView.frame.size.height
        let initialFrame = fromVC.view.frame

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                fromVC.view.frame = initialFrame.offsetBy(dx: 0.0, dy: dy)
            }, completion: { _ in transitionContext.completeTransition(!transitionContext.transitionWasCancelled) }
        )
    }

}

// MARK: - A

// [robertmryan](https://github.com/robertmryan)
// [robertmryan/SwiftCustomTransitions](https://github.com/robertmryan/SwiftCustomTransitions/tree/rightside)
// FIXME: the above are under a Creative Commons License
// https://stackoverflow.com/a/42213998/4472195
class SheetPresentationController: UIPresentationController {
    override var shouldRemovePresentersView: Bool { return false }

    var dimmerView: UIView!

    override func presentationTransitionWillBegin() {
        guard
            let transitionCoordinator = presentingViewController.transitionCoordinator,
            let `containerView` = containerView else {
                log.error("\(#function) FAILED : unable get transitionCoordinator or containerView"); return
        }

        dimmerView = UIView(frame: containerView.bounds)
        dimmerView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        dimmerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dimmerView.alpha = 0
        containerView.addSubview(dimmerView)
        transitionCoordinator.animate(alongsideTransition: { _ in self.dimmerView.alpha = 1 }, completion: nil)
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            dimmerView.removeFromSuperview()
            dimmerView = nil
        }
    }

    override func dismissalTransitionWillBegin() {
        guard let transitionCoordinator = presentingViewController.transitionCoordinator else {
            log.error("\(#function) FAILED : unable get transitionCoordinator"); return
        }
        transitionCoordinator.animate(alongsideTransition: { _ in self.dimmerView.alpha = 0 }, completion: nil)
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            dimmerView.removeFromSuperview()
            dimmerView = nil
        }
    }

}
