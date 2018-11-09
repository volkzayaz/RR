//
//  PlayerContentPresentationDelegate.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class PlayerContentTransitioningDelegate: NSObject {
    weak var presentingViewController: PlayerContentPresentingController?

    init(with presentingViewController: PlayerContentPresentingController?) {
        self.presentingViewController = presentingViewController
    }
}

extension PlayerContentTransitioningDelegate: UIViewControllerTransitioningDelegate {

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        return PlayerContentPresentationAnimator(presentingViewController: presentingViewController, isPresentation: true)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PlayerContentPresentationAnimator(presentingViewController: presentingViewController, isPresentation: false)
    }
}
