//
//  KaraokeRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol KaraokeRouter: FlowRouter {
}

final class DefaultKaraokeRouter:  KaraokeRouter, FlowRouterSegueCompatible {

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

    private(set) weak var viewModel: KaraokeViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultKaraokeRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .placeholder: break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: KaraokeViewController) {
        sourceController = controller
        let vm = KaraokeViewModel(router: self, lyricsKaraokeService: self.dependencies.lyricsKaraokeService)
        controller.configure(viewModel: vm, router: self)
    }
}
