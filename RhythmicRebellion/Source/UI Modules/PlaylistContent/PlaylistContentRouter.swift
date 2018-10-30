//
//  PlaylistContentRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlaylistContentRouter: FlowRouter {
    func showAddToPlaylist(for track: Track)
}

final class DefaultPlaylistContentRouter:  PlaylistContentRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case showAddToPlaylist = "showAddToPlaylist"
    }

    enum SegueActions: SegueDestinations {
        case showAddToPlaylist(track: Track)

        var identifier: SegueDestinationList {
            switch self {
            case .showAddToPlaylist: return SegueList.showAddToPlaylist
            }
        }
    }

    private(set) var dependencies: RouterDependencies

    private(set) weak var viewModel: PlaylistContentViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }


    func prepare(for destination: DefaultPlaylistContentRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .showAddToPlaylist(let track):
            guard let addToPlaylistViewController = (segue.destination as? UINavigationController)?.topViewController as? AddToPlaylistViewController else { fatalError("Incorrect controller for embedPlaylists") }
            let addToPlaylistRouter = DefaultAddToPlaylistRouter(dependencies: dependencies)
            addToPlaylistRouter.start(controller: addToPlaylistViewController, track: track)
            break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: PlaylistContentViewController, playlist: Playlist) {
        sourceController = controller

        let vm = PlaylistContentControllerViewModel(router: self,
                                                    application: self.dependencies.application,
                                                    player: self.dependencies.player,
                                                    restApiService: self.dependencies.restApiService,
                                                    audioFileLocalStorageService: self.dependencies.audioFileLocalStorageService,
                                                    playlist: playlist)

        controller.configure(viewModel: vm, router: self)
    }
    
    func showAddToPlaylist(for track: Track) {
        self.perform(segue: .showAddToPlaylist(track: track))
    }
}

extension DefaultPlaylistContentRouter {

}

