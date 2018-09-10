//
//  PlaylistsCollectionRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlaylistsCollectionRouter: FlowRouter {
    func showContent(of playlist: PlaylistShort)
}

final class DefaultPlaylistsCollectionRouter:  PlaylistsCollectionRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case playlistContent = "PlaylistContentSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case showPlaylistContent(playlist: PlaylistShort)

        var identifier: SegueDestinationList {
            switch self {
            case .showPlaylistContent: return SegueList.playlistContent
            }
        }
    }

    private(set) var dependencies: RouterDependencies
    
    private(set) weak var viewModel: PlaylistsCollectionViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultPlaylistsCollectionRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .showPlaylistContent(let playlist):
            guard let playlistContentViewController = segue.destination as? PlaylistContentViewController else { fatalError("Incorrect controller for PlaylistContentSegueIdentifier") }
            let playlistContentRouter = DefaultPlaylistContentRouter(dependencies: self.dependencies)
            playlistContentRouter.start(controller: playlistContentViewController, playlist: playlist)
            break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: PlaylistsCollectionViewController) {
        sourceController = controller
        let vm = FanPlaylistsCollectionControllerViewModel(router: self, restApiService: self.dependencies.restApiService, application : dependencies.application)
        controller.configure(viewModel: vm, router: self)
    }
    
    func showContent(of playlist: PlaylistShort) {
        self.perform(segue: .showPlaylistContent(playlist: playlist))
    }
}
