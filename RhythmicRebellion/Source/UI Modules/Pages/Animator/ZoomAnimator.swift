//
//  ZoomAnimator.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/19/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol ZoomAnimatorSourceImageContainerView: class {
    var image: UIImage? { get }
    var imageContentMode: UIViewContentMode { get }
}

protocol ZoomAnimatorSourceViewController: class {
    func transitionWillBegin(with animator: ZoomAnimator, for viewController: UIViewController)
    func transitionDidEnd(with animator: ZoomAnimator, for viewController: UIViewController)

    func sourceImageContainerView(for animator: ZoomAnimator, for viewController: UIViewController) -> (UIView & ZoomAnimatorSourceImageContainerView)?
}


protocol ZoomAnimatorDestinationViewController: class {

    func transitionWillBegin(with animator: ZoomAnimator)
    func transitionDidEnd(with animator: ZoomAnimator)

    func referenceImageView(for animator: ZoomAnimator) -> UIImageView?
}

class ZoomAnimator: NSObject {

    let isPresentation: Bool

    weak var transitionImageView: UIImageView?

    init(isPresentation: Bool) {
        self.isPresentation = isPresentation
    }

    private func animateZoomInTransition(using transitionContext: UIViewControllerContextTransitioning) {

        guard let toViewController = transitionContext.viewController(forKey: .to) as? UIViewController & ZoomAnimatorDestinationViewController,
            let fromViewController = transitionContext.viewController(forKey: .from) as? UIViewController & ZoomAnimatorSourceViewController else { return }

        let containerView = transitionContext.containerView

        fromViewController.transitionWillBegin(with: self, for: toViewController)
        toViewController.transitionWillBegin(with: self)

        guard let sourceImageContainerView = fromViewController.sourceImageContainerView(for: self, for: toViewController),
            let sourceImageContainerViewSuperview = sourceImageContainerView.superview else { return }

        let toReferenceImageView = toViewController.referenceImageView(for: self)
        toReferenceImageView?.image = sourceImageContainerView.image
        toReferenceImageView?.contentMode = sourceImageContainerView.contentMode

        containerView.addSubview(toViewController.view)

        let fromFrame = sourceImageContainerViewSuperview.convert(sourceImageContainerView.frame, to: containerView)

        if self.transitionImageView == nil {
            let transitionImageView = UIImageView(frame: fromFrame)
            transitionImageView.image = sourceImageContainerView.image
            transitionImageView.contentMode = sourceImageContainerView.contentMode
//            transitionImageView.clipsToBounds = true
            self.transitionImageView = transitionImageView
            containerView.addSubview(transitionImageView)
        }

        toViewController.view.alpha = 0.0

        sourceImageContainerView.isHidden = true
        toReferenceImageView?.isHidden = true

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0,
                       options: [UIViewAnimationOptions.transitionCrossDissolve],
                       animations: {
                        self.transitionImageView?.frame = transitionContext.finalFrame(for: toViewController)
        },
                       completion: { completed in

                        toViewController.view.alpha = 1.0

                        self.transitionImageView?.removeFromSuperview()

                        sourceImageContainerView.isHidden = false
                        toReferenceImageView?.isHidden = false

                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

                        fromViewController.transitionDidEnd(with: self, for: toViewController)
                        toViewController.transitionDidEnd(with: self)

        })

    }

    private func animateZoomOutTransition(using transitionContext: UIViewControllerContextTransitioning) {

        guard let toViewController = transitionContext.viewController(forKey: .to) as? UIViewController & ZoomAnimatorSourceViewController ,
            let fromViewController = transitionContext.viewController(forKey: .from) as? UIViewController & ZoomAnimatorDestinationViewController else { return }

        let containerView = transitionContext.containerView

        toViewController.transitionWillBegin(with: self, for: fromViewController)
        fromViewController.transitionWillBegin(with: self)

        guard let sourceImageContainerView = toViewController.sourceImageContainerView(for: self, for: fromViewController),
            let sourceImageContainerViewSuperview = sourceImageContainerView.superview else { return }

        containerView.insertSubview(toViewController.view, belowSubview: fromViewController.view)

        if self.transitionImageView == nil {
            let transitionImageView = UIImageView(frame: fromViewController.view.bounds)
            transitionImageView.image = sourceImageContainerView.image
            transitionImageView.contentMode = sourceImageContainerView.contentMode
//            transitionImageView.clipsToBounds = true
            self.transitionImageView = transitionImageView
            containerView.addSubview(transitionImageView)
        }

        fromViewController.view.alpha = 0
        sourceImageContainerView.isHidden = true

        let toFrame = sourceImageContainerViewSuperview.convert(sourceImageContainerView.frame, to: containerView)

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0,
                       options: [UIViewAnimationOptions.transitionCrossDissolve],
                       animations: {
                        self.transitionImageView?.frame = toFrame
        },
                       completion: { completed in

                        self.transitionImageView?.removeFromSuperview()
                        sourceImageContainerView.isHidden = false

                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                        
                        fromViewController.transitionDidEnd(with: self)
                        toViewController.transitionDidEnd(with: self, for: toViewController)
        })
    }

    private func calculateZoomInImageFrame(image: UIImage, forView view: UIView) -> CGRect {

        let viewRatio = view.frame.size.width / view.frame.size.height
        let imageRatio = image.size.width / image.size.height
        let touchesSides = (imageRatio > viewRatio)

        if touchesSides {
            let height = view.frame.width / imageRatio
            let yPoint = view.frame.minY + (view.frame.height - height) / 2
            return CGRect(x: 0, y: yPoint, width: view.frame.width, height: height)
        } else {
            let width = view.frame.height * imageRatio
            let xPoint = view.frame.minX + (view.frame.width - width) / 2
            return CGRect(x: xPoint, y: 0, width: width, height: view.frame.height)
        }
    }
}


extension ZoomAnimator : UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionContext?.isAnimated == true ? 1.0 : 0.0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        print("transitionContext.isAnimated: \(transitionContext.isAnimated)")

        if self.isPresentation {
            self.animateZoomInTransition(using: transitionContext)
        } else {
            self.animateZoomOutTransition(using: transitionContext)
        }
    }
}
