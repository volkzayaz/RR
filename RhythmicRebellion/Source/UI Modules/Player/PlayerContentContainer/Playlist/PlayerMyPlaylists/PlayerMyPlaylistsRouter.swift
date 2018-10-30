//
//  PlayerMyPlaylistsRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerMyPlaylistsRouter: FlowRouter {
    func showContent(of playlist: FanPlaylist)
}

final class DefaultPlayerMyPlaylistsRouter:  PlayerMyPlaylistsRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case playlistContent = "PlaylistContentSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case showPlaylistContent(playlist: FanPlaylist)

        var identifier: SegueDestinationList {
            switch self {
            case .showPlaylistContent: return SegueList.playlistContent
            }
        }
    }

    private(set) var dependencies: RouterDependencies

    private(set) weak var viewModel: PlayerMyPlaylistsViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultPlayerMyPlaylistsRouter.SegueActions, segue: UIStoryboardSegue) {
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

    func start(controller: PlayerMyPlaylistsViewController) {
        sourceController = controller
        let vm = PlayerMyPlaylistsControllerViewModel(router: self, restApiService: self.dependencies.restApiService, application : dependencies.application)
        controller.configure(viewModel: vm, router: self)
    }

    func showContent(of playlist: FanPlaylist) {
        self.perform(segue: .showPlaylistContent(playlist: playlist))
    }
}
