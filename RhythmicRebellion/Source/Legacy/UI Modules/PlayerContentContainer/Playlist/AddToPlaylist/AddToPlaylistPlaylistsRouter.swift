//
//  AddToPlaylistRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol AddToPlaylistRouter: FlowRouter {
    func dismiss()
}

final class DefaultAddToPlaylistRouter:  AddToPlaylistRouter, FlowRouterSegueCompatible {

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
    
    private(set) weak var viewModel: AddToPlaylistViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultAddToPlaylistRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        default: break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: AddToPlaylistViewController, tracks: [Track]) {
        sourceController = controller
        let vm = AddTracksToPlaylistControllerViewModel(router: self, tracks: tracks)
        controller.configure(viewModel: vm, router: self)
    }

    func start(controller: AddToPlaylistViewController, playlist: Playlist) {
        sourceController = controller
        let vm = AddPlaylistToPlaylistControllerViewModel(router: self, playlist: playlist)
        controller.configure(viewModel: vm, router: self)
    }

    
    func dismiss() {
        self.sourceController?.dismiss(animated: true, completion: nil)
    }
}
