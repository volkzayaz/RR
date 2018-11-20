//
//  PageContentRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/15/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PageContentRouter: FlowRouter {
}

final class DefaultPageContentRouter:  PageContentRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case placeholder = "placeholder"
    }

    enum SegueActions: SegueDestinations {
        case placeholder

        var identifier: SegueDestinationList {
            switch self {
            case .placeholder: return SegueList.placeholder
            }
        }
    }

    private(set) weak var viewModel: PageContentViewModel?
    private(set) weak var sourceController: UIViewController?

    private(set) var dependencies: RouterDependencies
    private(set) var pagesLocalStorage: PagesLocalStorageService

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultPageContentRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .placeholder: break
        }
    }

    init(dependencies: RouterDependencies, pagesLocalStorage: PagesLocalStorageService) {
        self.dependencies = dependencies
        self.pagesLocalStorage = pagesLocalStorage
    }

    func start(controller: PageContentViewController, page: Page) {
        sourceController = controller
        let vm = PageContentControllerViewModel(router: self, page: page, pagesLocalStorage: self.pagesLocalStorage)
        controller.configure(viewModel: vm, router: self)
    }
}
