//
//  Interactor.swift
//  InteractiveModal
//
//  Created by Robert Chen on 1/18/16.
//  Copyright © 2016 Thorn Technologies. All rights reserved.
//

import UIKit

class PanDismissInteractor: UIPercentDrivenInteractiveTransition, UIViewControllerTransitioningDelegate {
    
    func present(vc: UIViewController, on presenter: UIViewController) {
        vc.transitioningDelegate = self
        vc.modalPresentationCapturesStatusBarAppearance = true
        
        owner = vc
        
        let x = UIPanGestureRecognizer(target: self, action: "didPan:")
        
        presenter.present(vc, animated: true, completion: {
            vc.view.addGestureRecognizer(x)
        })
    }
    
    var hasStarted = false
    var shouldFinish = false
    weak var owner: UIViewController?
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return hasStarted ? self : nil
    }

    @objc func didPan(_ sender: UIPanGestureRecognizer) {
        
        let percentThreshold:CGFloat = 0.3
        let view = sender.view!
        // convert y-position to downward pull progress (percentage)
        let translation = sender.translation(in: view)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)
        
        switch sender.state {
        case .began:
            hasStarted = true
            owner?.dismiss(animated: true, completion: nil)
        case .changed:
            shouldFinish = progress > percentThreshold
            update(progress)
        case .cancelled:
            hasStarted = false
            cancel()
        case .ended:
            hasStarted = false
            shouldFinish
                ? finish()
                : cancel()
        default:
            break
        }
    }
    
}

class DismissAnimator : NSObject {
}

extension DismissAnimator : UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
            else {
                return
        }
        
        transitionContext.containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        
        let screenBounds = UIScreen.main.bounds
        let bottomLeftCorner = CGPoint(x: 0, y: screenBounds.height)
        let finalFrame = CGRect(origin: bottomLeftCorner, size: screenBounds.size)
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                fromVC.view.frame = finalFrame
        },
            completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        )
    }
}
