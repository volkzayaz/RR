//
//  MyPlaylistsRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class MyPlaylistsRouter: FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case playlistContent = "PlaylistContentSegueIdentifier"
        case addToPlaylist = "AddToPlaylistSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case showPlaylistContent(playlist: FanPlaylist)
        case showAddToPlaylist(playlist: FanPlaylist)

        var identifier: SegueDestinationList {
            switch self {
            case .showPlaylistContent: return SegueList.playlistContent
            case .showAddToPlaylist: return SegueList.addToPlaylist
            }
        }
    }

    private(set) var dependencies: RouterDependencies

    private(set) weak var viewModel: MyPlaylistsViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: MyPlaylistsRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .showPlaylistContent(let playlist):
            guard let playlistContentViewController = segue.destination as? PlaylistContentViewController else { fatalError("Incorrect controller for PlaylistContentSegueIdentifier") }
            let playlistContentRouter = PlaylistRouter(dependencies: self.dependencies)
            playlistContentRouter.start(controller: playlistContentViewController, playlist: playlist)

        case .showAddToPlaylist(let playlist):
            guard let addToPlaylistViewController = (segue.destination as? UINavigationController)?.topViewController as? AddToPlaylistViewController else { fatalError("Incorrect controller for embedPlaylists") }
            let addToPlaylistRouter = AddToPlaylistRouter(dependencies: dependencies)
            addToPlaylistRouter.start(controller: addToPlaylistViewController, playlist: playlist)
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: MyPlaylistsViewController) {
        sourceController = controller
        let vm = MyPlaylistsViewModel(router: self)
                                                      
        controller.configure(viewModel: vm, router: self)
    }

    func showContent(of playlist: FanPlaylist) {
        self.perform(segue: .showPlaylistContent(playlist: playlist))
    }

    func showAddToPlaylist(for playlist: FanPlaylist) {
        self.perform(segue: .showAddToPlaylist(playlist: playlist))
    }
}
