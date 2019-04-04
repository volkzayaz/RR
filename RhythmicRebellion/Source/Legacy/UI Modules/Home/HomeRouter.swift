//
//  HomeRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol HomeRouter: FlowRouter {
    func showContent(of playlist: Playlist)

    func showAddToPlaylist(for playlist: Playlist)
    
}

final class DefaultHomeRouter:  HomeRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case playlistContent = "PlaylistContentSegueIdentifier"
        case addToPlaylist = "AddToPlaylistSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case showPlaylistContent(playlist: Playlist)
        case showAddToPlaylist(playlist: Playlist)

        var identifier: SegueDestinationList {
            switch self {
            case .showPlaylistContent: return SegueList.playlistContent
            case .showAddToPlaylist: return SegueList.addToPlaylist
            }
        }
    }

    private(set) var dependencies: RouterDependencies
    
    private(set) weak var viewModel: HomeViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultHomeRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .showPlaylistContent(let playlist):
            guard let playlistContentViewController = segue.destination as? PlaylistContentViewController else { fatalError("Incorrect controller for PlaylistContentSegueIdentifier") }
            let playlistContentRouter = DefaultPlaylistContentRouter(dependencies: self.dependencies)
            playlistContentRouter.start(controller: playlistContentViewController, playlist: playlist)

        case .showAddToPlaylist(let playlist):
            guard let addToPlaylistViewController = (segue.destination as? UINavigationController)?.topViewController as? AddToPlaylistViewController else { fatalError("Incorrect controller for embedPlaylists") }
            let addToPlaylistRouter = DefaultAddToPlaylistRouter(dependencies: dependencies)
            addToPlaylistRouter.start(controller: addToPlaylistViewController, playlist: playlist)
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: HomeViewController) {
        sourceController = controller
        let vm = HomeControllerViewModel(router: self, application: self.dependencies.application)
        controller.configure(viewModel: vm, router: self)
    }

    func showContent(of playlist: Playlist) {
        self.perform(segue: .showPlaylistContent(playlist: playlist))
    }

    func showAddToPlaylist(for playlist: Playlist) {
        self.perform(segue: .showAddToPlaylist(playlist: playlist))
    }
}
