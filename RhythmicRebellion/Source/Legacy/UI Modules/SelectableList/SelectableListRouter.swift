//
//  SelectableListRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/31/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol SelectableListRouter: FlowRouter {
    func done()
}

final class DefaultSelectableListRouter:  SelectableListRouter, FlowRouterSegueCompatible {

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

    private(set) var dependencies: RouterDependencies

    private(set) weak var viewModel: SelectableListViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultSelectableListRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .placeholder: break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

//    func start(controller: SelectableListViewController, selectionType: .single) {
//        sourceController = controller
//        let vm = SelectableListControllerViewModel(router: self, )
//        controller.configure(viewModel: vm, router: self)
//    }

    func start<T: SelectableListItemsDataProvider>(controller: SelectableListViewController, viewModel: SelectableListControllerViewModel<T>) {
        sourceController = controller
        controller.configure(viewModel: viewModel, router: self)
    }

    func done() {
        self.sourceController?.navigationController?.popViewController(animated: true)
    }

}

