//
//  LyricsRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol LyricsRouterDelegate: ForcedAuthorizationRouter {
}

protocol LyricsRouter: FlowRouter, ForcedAuthorizationRouter {
}

final class DefaultLyricsRouter:  LyricsRouter, FlowRouterSegueCompatible {

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

    
    private(set) weak var delegate: LyricsRouterDelegate?

    private(set) weak var viewModel: LyricsViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultLyricsRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .placeholder: break
        }
    }

    init( delegate: LyricsRouterDelegate? = nil) {
        
        self.delegate = delegate
    }

    func start(controller: LyricsViewController) {
        sourceController = controller
        let vm = LyricsViewModel(router: self)
        controller.configure(viewModel: vm, router: self)
    }

    func routeToAuthorization(with authorizationType: AuthorizationType) {
        self.delegate?.routeToAuthorization(with: .signIn)
    }
}
