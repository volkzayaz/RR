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

final class DefaultPlayerMyPlaylistsRouter:  PlayerMyPlaylistsRouter, SegueCompatible {

    typealias Destinations = SegueList

    enum SegueList: String, SegueDestinations {
        case embedPlaylists

        var identifier: String {
            switch self {
            case .embedPlaylists: return "embedPlaylists"
            }
        }

        static func from(identifier: String) -> SegueList? {
            switch identifier {
            case "embedPlaylists" : return .embedPlaylists
            default: return nil
            }
        }
    }

    private(set) var dependencies: RouterDependencies
    
    private(set) weak var viewModel: PlayerMyPlaylistsViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let payload = merge(segue: segue, with: sender) else { return }

        switch payload {
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
