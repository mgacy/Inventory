//
//  NavigationController.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/12/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {

    var detailView: DetailView<UIViewController> = .empty

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = ColorPalette.hintOfRed
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        //log.debug("\(#function) : \(String(describing: topViewController.self))")
        if case .visible(let detailViewController) = detailView {
            if topViewController === detailViewController {
                //log.debug("\(#function) : POPPED DETAIL")
                detailView = .empty
            } else {
                // Set detail view controller to empty to prevent confusion
                // FIXME: it's really ugly that we are reaching up into splitViewController to get its detail nav controller
                if
                    let splitViewController = splitViewController,
                    splitViewController.viewControllers.count > 1,
                    let detailNavigationController = splitViewController.viewControllers.last as? UINavigationController
                {
                    detailNavigationController.setViewControllers([makeEmptyViewController()], animated: true)
                    detailView = .empty
                }
            }
        }
        return super.popViewController(animated: animated)
    }

}

// MARK: - PrimaryContainerType

extension NavigationController: PrimaryContainerType {

    /// Add detail view controller to `viewControllers` if it is visible.
    func collapseDetail() {
        switch detailView {
        case .visible(let detailViewController):
            viewControllers += [detailViewController]
        case .empty:
            return
        }
    }

    /// Remove detail view controller from `viewControllers` if it is visible.
    func separateDetail() {
        switch detailView {
        case .visible:
            viewControllers.removeLast()
        case .empty:
            return
        }
    }

    func makeEmptyViewController() -> UIViewController {
        return EmptyDetailViewController()
    }

}

// MARK: - Detail -

class DetailNavigationController: UINavigationController {

    init() {
        super.init(nibName: nil, bundle: nil)
        delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = ColorPalette.hintOfRed
        view.backgroundColor = .white
    }

}

// MARK: - UINavigationControllerDelegate
extension DetailNavigationController: UINavigationControllerDelegate {

    /// TODO: instantiate NavigationControllerAnimation (Animator) just once

    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        guard operation == .push, toVC is EmptyDetailViewController else {
            return nil
        }

        return NavigationControllerAnimator(operation: operation)
        //return nil
    }

}

// https://stackoverflow.com/a/41528045/4472195
// https://gist.github.com/alanzeino/603293f9da5cd0b7f6b60dc20bc766be
class NavigationControllerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let operation: UINavigationControllerOperation

    init(operation: UINavigationControllerOperation) {
        self.operation = operation
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
                return
        }

        if operation == .push {
            //animatePush(from: fromViewController, to: toViewController, using: transitionContext)
            switch toVC is EmptyDetailViewController {
            case true:
                animatePushAsPop(from: fromVC, to: toVC, using: transitionContext)
            case false:
                animatePush(from: fromVC, to: toVC, using: transitionContext)
            }
        } else if operation == .pop {
            animatePop(from: fromVC, to: toVC, using: transitionContext)
        }
    }

    // MARK: - Push / Pop

    private func animatePush(from fromVC: UIViewController, to toVC: UIViewController, using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toVC)

        let dx = containerView.frame.size.width
        toVC.view.frame = finalFrame.offsetBy(dx: dx, dy: 0.0)
        containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext), delay: 0,
            options: [ UIViewAnimationOptions.curveEaseOut ],
            animations: {
                toVC.view.frame = transitionContext.finalFrame(for: toVC)
                fromVC.view.frame = finalFrame.offsetBy(dx: dx / -2.5, dy: 0.0)
        },
            completion: { (finished) in transitionContext.completeTransition(true) }
        )
    }

    private func animatePushAsPop(from fromVC: UIViewController, to toVC: UIViewController, using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toVC)

        let dx = containerView.frame.size.width
        toVC.view.frame = finalFrame.offsetBy(dx: dx / -2.5, dy: 0.0)
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext), delay: 0,
            options: [ UIViewAnimationOptions.curveEaseOut ],
            animations: {
                toVC.view.frame = transitionContext.finalFrame(for: toVC)
                fromVC.view.frame = finalFrame.offsetBy(dx: dx, dy: 0.0)
        },
            completion: { (finished) in transitionContext.completeTransition(true) }
        )
    }

    private func animatePop(from fromVC: UIViewController, to toVC: UIViewController, using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext), delay: 0,
            options: [ UIViewAnimationOptions.curveEaseOut ],
            animations: {
                fromVC.view.frame = containerView.bounds.offsetBy(dx: containerView.frame.width, dy: 0)
                toVC.view.frame = containerView.bounds
        },
            completion: { (finished) in transitionContext.completeTransition(true) }
        )
    }

}
