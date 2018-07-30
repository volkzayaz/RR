//
//  PlayerContentPresentationDelegate.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class PlayerContentTransitioningDelegate: NSObject {

}

extension PlayerContentTransitioningDelegate: UIViewControllerTransitioningDelegate {

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        //        let presentationController = PlayerContentPresentationController(presentedViewController: presented, presentingViewController: presenting, sourceViewController: sourceViewController)

        let presentationController = PlayerContentPresentationController(presentedViewController: presented, presentingViewController: source, sourceViewController: source)

        return presentationController
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PlayerContentPresentationAnimator(isPresentation: true)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PlayerContentPresentationAnimator(isPresentation: false)
    }
}
