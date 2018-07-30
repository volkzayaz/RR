//
//  TabBarPresentationController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class PlayerContentPresentationController: UIPresentationController {

    let sourceViewController: UIViewController

    override var presentingViewController: UIViewController { return self.sourceViewController }

    override var shouldPresentInFullscreen: Bool { return false }
    override var presentationStyle: UIModalPresentationStyle { return .currentContext }

    init(presentedViewController: UIViewController, presentingViewController: UIViewController?, sourceViewController: UIViewController) {
        self.sourceViewController = sourceViewController
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        self.containerView?.frame = self.containerViewFrame
    }

    var tabBarViewController: UITabBarController? { return self.presentedViewController as? UITabBarController }

    override var frameOfPresentedViewInContainerView: CGRect {
        var frame = super.frameOfPresentedViewInContainerView

//        guard let tabBarViewController = self.sourceViewController as? UITabBarController, tabBarViewController.tabBar.isHidden == false else { return frame }
//
//        frame.size.height -= tabBarViewController.tabBar.frame.height

        return frame
    }

    var containerViewFrame: CGRect {
        guard let tabBarViewController = self.sourceViewController as? UITabBarController else { return self.presentingViewController.view.bounds }

        var frame = tabBarViewController.view.frame

        guard tabBarViewController.tabBar.isHidden == false else { return frame }

        frame.size.height -= tabBarViewController.tabBar.frame.height

        return frame
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        self.presentedView?.frame = self.frameOfPresentedViewInContainerView
    }

    override func presentationTransitionWillBegin() {
        self.containerView?.frame = self.containerViewFrame
        self.sourceViewController.view.addSubview(self.containerView!)
    }
}
