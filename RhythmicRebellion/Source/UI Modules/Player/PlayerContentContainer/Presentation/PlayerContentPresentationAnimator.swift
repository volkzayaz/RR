//
//  PlayerContentPresentationAnimator.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol PlayerContentPresentingController: class {
    func frame(for containerView: UIView) -> CGRect
    func destinationFrame(for presentedViewController: UIViewController, in containerView: UIView) -> CGRect
}

class PlayerContentPresentationAnimator: NSObject {

    let isPresentation: Bool
    weak var presentingViewController: PlayerContentPresentingController?

    init(presentingViewController: PlayerContentPresentingController?, isPresentation: Bool) {
        self.isPresentation = isPresentation
        self.presentingViewController = presentingViewController
        super.init()
    }
}

extension PlayerContentPresentationAnimator: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func frame(for containerView: UIView) -> CGRect {
        guard let presentingViewController = self.presentingViewController else { return containerView.frame}

        return presentingViewController.frame(for: containerView)
    }

    func destinationFrame(for presentedViewController: UIViewController, in containerView: UIView) -> CGRect {
        guard let presentingViewController = self.presentingViewController else { return containerView.frame }

        return presentingViewController.destinationFrame(for: presentedViewController, in: containerView)
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = isPresentation ? UITransitionContextViewControllerKey.to : UITransitionContextViewControllerKey.from
        let controller = transitionContext.viewController(forKey: key)!

        transitionContext.containerView.frame = self.frame(for: transitionContext.containerView)

        if isPresentation {
            transitionContext.containerView.addSubview(controller.view)
        }
        let presentedFrame = isPresentation ? self.destinationFrame(for: controller, in: transitionContext.containerView) : controller.view.frame
        var dismissedFrame = presentedFrame

        dismissedFrame.origin.y = -transitionContext.containerView.frame.size.height

        let initialFrame = isPresentation ? dismissedFrame : presentedFrame
        let finalFrame = isPresentation ? presentedFrame : dismissedFrame

        let animationDuration = transitionDuration(using: transitionContext)
        controller.view.frame = initialFrame
        UIView.animate(withDuration: animationDuration, animations: {
            controller.view.frame = finalFrame
        }) { finished in
            transitionContext.completeTransition(finished)
        }
    }
}
