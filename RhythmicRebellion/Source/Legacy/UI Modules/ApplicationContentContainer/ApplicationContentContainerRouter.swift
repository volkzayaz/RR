//
//  ApplicationContentContainerRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/7/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class ApplicationContentContainerRouter: FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case tabBarController = "TabBarControllerSegueIdentifier"
        case playerContentController = "PlayerContantControllerSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case tabBarController
        case showPlayerContentController(playerNavigationItem: PlayerNavigationItem)

        var identifier: SegueDestinationList {
            switch self {
            case .tabBarController: return SegueList.tabBarController
            case .showPlayerContentController: return SegueList.playerContentController
            }
        }

        init?(destinationList: SegueDestinationList) {
            switch destinationList as? SegueList {
            case .tabBarController?: self = .tabBarController
            default: fatalError("Unknown destination!")
            }
        }
    }

    private(set) weak var applicationContentContainerViewController: ApplicationContentContainerViewController?
    var sourceController: UIViewController? { return applicationContentContainerViewController }

    private(set) weak var tabBarRouter: TabBarRouter?

    lazy var playerContentTransitioningDelegate = PlayerContentTransitioningDelegate(with: self)

    var playerContentContainerRouter: PlayerContentContainerRouter? { return self.tabBarRouter?.playerContentContainerRouter}

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: ApplicationContentContainerRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .tabBarController:
            guard let tabBarViewController = segue.destination as? TabBarViewController else { fatalError("Incorrect controller for TabBarSegueIdentifier") }
            let tabBarRouter = TabBarRouter(owner: tabBarViewController)
            
            tabBarViewController.viewModel = TabBarViewModel(router: tabBarRouter)
            
            self.tabBarRouter = tabBarRouter
            self.applicationContentContainerViewController?.tabBarViewController = tabBarViewController
            


        case .showPlayerContentController(let playerNavigationItem):
            guard let playerContentContainerViewController = segue.destination as? PlayerContentContainerViewController else { fatalError("Incorrect controller for PlayerContantContainerSegueIdentifier") }

            playerContentContainerViewController.transitioningDelegate = self.playerContentTransitioningDelegate
            playerContentContainerViewController.modalPresentationStyle = .overCurrentContext

            let playerContentContainerRouter = DefaultPlayerContentContainerRouter(navigationDelegate: self)
            playerContentContainerRouter.start(controller: playerContentContainerViewController, navigationItem: playerNavigationItem)

            self.applicationContentContainerViewController?.playerContentContainerViewController = playerContentContainerViewController
            self.tabBarRouter?.playerContentContainerRouter = playerContentContainerRouter
        }
    }

    

    func start(controller: ApplicationContentContainerViewController) {
        applicationContentContainerViewController = controller
        let vm = ApplicationContentContainerControllerViewModel(router: self)
        controller.configure(viewModel: vm, router: self)
    }

    func showPlayerContentContainer(playerNavigationItem: PlayerNavigationItem) {
        self.tabBarRouter?.tabBarViewController?.selectedViewController?.view.endEditing(true)
        self.perform(segue: .showPlayerContentController(playerNavigationItem: playerNavigationItem))
    }
}

extension ApplicationContentContainerRouter: PlayerNavigationDelgate {
    func routeToAuthorization(with authorizationType: AuthorizationType) {
        self.tabBarRouter?.routeToAuthorization(with: authorizationType)
    }


    func navigate(to playerNavigationItem: PlayerNavigationItem) {

        guard let playerContentContainerRouter = self.tabBarRouter?.playerContentContainerRouter else {
            self.tabBarRouter?.tabBarViewController?.selectedViewController?.view.endEditing(true)
            self.perform(segue: .showPlayerContentController(playerNavigationItem: playerNavigationItem))
            return
        }

        playerContentContainerRouter.navigate(to: playerNavigationItem)
    }
}

extension ApplicationContentContainerRouter: PlayerContentPresentingController {

    func frame(for containerView: UIView) -> CGRect {
        guard let destinationViewController = self.applicationContentContainerViewController?.tabBarViewController,
            let destinationViewControllerSuperview = destinationViewController.view.superview,
            let containerViewSuperview = containerView.superview else { return containerView.frame}

        var destinationViewControllerFrame = containerViewSuperview.convert(destinationViewController.view.frame, from: destinationViewControllerSuperview)

        destinationViewControllerFrame.size.height += destinationViewControllerFrame.origin.y

        if destinationViewController.tabBar.isHidden == false {
            destinationViewControllerFrame.size.height -= destinationViewController.tabBar.frame.height
        }

        return CGRect(origin: containerView.frame.origin, size: destinationViewControllerFrame.size)
    }

    func destinationFrame(for presentedViewController: UIViewController, in containerView: UIView) -> CGRect {
        guard let destinationViewController = self.applicationContentContainerViewController?.tabBarViewController,
            let destinationViewControllerSuperview = destinationViewController.view.superview else { return containerView.frame }

        let destinationFrameOrigin = containerView.convert(destinationViewController.view.frame.origin, from: destinationViewControllerSuperview)
        let size = CGSize(width: containerView.frame.width, height: containerView.frame.height - destinationFrameOrigin.y)

        return CGRect(origin: destinationFrameOrigin, size: size)
    }
}

extension ApplicationContentContainerRouter: PlayerContentNavigationDelgate {


    func navigateToPage(with url: URL) {
        self.tabBarRouter?.tabBarViewController?.selectPage(with: url)
    }
}
