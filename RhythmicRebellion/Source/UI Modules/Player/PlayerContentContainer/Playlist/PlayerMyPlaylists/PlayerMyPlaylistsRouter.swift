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
}

final class DefaultPlayerMyPlaylistsRouter:  PlayerMyPlaylistsRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case embedPlaylists = "embedPlaylists"
    }

    enum SegueActions: SegueDestinations {
        case embedPlaylists

        var identifier: SegueDestinationList {
            switch self {
            case .embedPlaylists: return SegueList.embedPlaylists
            }
        }

        init?(destinationList: SegueDestinationList) {
            switch destinationList as? SegueList {
            case .embedPlaylists?: self = .embedPlaylists
            default: fatalError("UPS!")
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
        case .embedPlaylists:
            guard let playlistsCollectionViewController = segue.destination as? PlaylistsCollectionViewController else { fatalError("Incorrect controller for embedPlaylists") }
            let playlistCollectionRouter = DefaultPlaylistsCollectionRouter(dependencies: self.dependencies)
            playlistCollectionRouter.start(controller: playlistsCollectionViewController)
            break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: PlayerMyPlaylistsViewController) {
        sourceController = controller
        let vm = PlayerMyPlaylistsControllerViewModel(router: self)
        controller.configure(viewModel: vm, router: self)
    }
}
