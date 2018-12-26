//
//  PagesRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PagesRouter: FlowRouter, PageContentRouterDelegate {

    func navigate(to page: Page, animated: Bool)
}

final class DefaultPagesRouter: NSObject, PagesRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case pageContent = "PageContentSegueIdentifier"
        case animatedPageContent = "AnimatedPageContentSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case showPageContent(page: Page)
        case showPageContentAnimated(page: Page)

        var identifier: SegueDestinationList {
            switch self {
            case .showPageContent: return SegueList.pageContent
            case .showPageContentAnimated: return SegueList.animatedPageContent
            }
        }
    }

    private(set) var dependencies: RouterDependencies
    private(set) weak var authorizationNavigationDelgate: ForcedAuthorizationRouter?
    
    private(set) weak var viewModel: PagesViewModel?
    private(set) weak var pagesViewController: PagesViewController?
    var sourceController: UIViewController? { return self.pagesViewController }

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultPagesRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .showPageContent(let page):
            guard let pageContentViewController = segue.destination as? PageContentViewController else { fatalError("Incorrect controller for PageContentSegueIdentifier") }
            let pageContentRouter = DefaultPageContentRouter(dependencies: self.dependencies, delegate: self)
            pageContentRouter.start(controller: pageContentViewController, page: page)

        case .showPageContentAnimated(let page):
            guard let pageContentViewController = segue.destination as? PageContentViewController else { fatalError("Incorrect controller for PageContentSegueIdentifier") }
            let pageContentRouter = DefaultPageContentRouter(dependencies: self.dependencies, delegate: self)
            pageContentRouter.start(controller: pageContentViewController, page: page)

        }
    }

    init(dependencies: RouterDependencies, authorizationNavigationDelgate: ForcedAuthorizationRouter?) {
        self.dependencies = dependencies
        self.authorizationNavigationDelgate = authorizationNavigationDelgate

        super.init()
    }

    func start(controller: PagesViewController) {
        pagesViewController = controller
        controller.navigationController?.delegate = self
        let vm = PagesControllerViewModel(router: self, pagesLocalStorage: self.dependencies.pagesLocalStorageService)
        controller.configure(viewModel: vm, router: self)
    }

    func navigate(to page: Page, animated: Bool) {

        self.sourceController?.navigationController?.popToRootViewController(animated: false)

        self.perform(segue: animated ? .showPageContentAnimated(page: page) : .showPageContent(page: page))
    }
}

extension DefaultPagesRouter: PageContentRouterDelegate {
    func routeToAuthorization(with authorizationType: AuthorizationType) {
        self.authorizationNavigationDelgate?.routeToAuthorization(with: authorizationType)
    }

    func pageFailed(with error: Error) {
        self.pagesViewController?.navigationController?.popViewController(animated: true)

        self.pagesViewController?.viewModel.show(error: error)

    }
}

extension DefaultPagesRouter : UINavigationControllerDelegate {

    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
    }

    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
    }

    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        switch operation {
        case .push:
            guard fromVC as? ZoomAnimatorSourceViewController != nil,
                toVC as? ZoomAnimatorDestinationViewController != nil else { return nil }

            return ZoomAnimator(isPresentation: true)

        case .pop:
            guard fromVC as? ZoomAnimatorDestinationViewController != nil,
                toVC as? ZoomAnimatorSourceViewController != nil else { return nil }

            return ZoomAnimator(isPresentation: false)

        default: return nil
        }
    }

}
