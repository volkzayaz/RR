//
//  VideoRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol VideoRouter: FlowRouter {
}

final class DefaultVideoRouter:  VideoRouter, FlowRouterSegueCompatible {

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
    
    private(set) weak var viewModel: VideoViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultVideoRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .placeholder: break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: VideoViewController) {
        sourceController = controller
        let vm = VideoControllerViewModel(router: self)
        controller.configure(viewModel: vm, router: self)
    }
}
