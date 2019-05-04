//
//  HomeRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class HomeRouter: FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case addToPlaylist = "AddToPlaylistSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case showAddToPlaylist(playlist: Playlist)

        var identifier: SegueDestinationList {
            switch self {
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

    func prepare(for destination: HomeRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        
        case .showAddToPlaylist(let playlist):
            guard let addToPlaylistViewController = (segue.destination as? UINavigationController)?.topViewController as? AddToPlaylistViewController else { fatalError("Incorrect controller for embedPlaylists") }
            let addToPlaylistRouter = AddToPlaylistRouter()
            addToPlaylistRouter.start(controller: addToPlaylistViewController, playlist: playlist)
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: HomeViewController) {
        sourceController = controller
        let vm = HomeControllerViewModel(router: self)
        controller.configure(viewModel: vm, router: self)
    }

    func showContent(of playlist: DefinedPlaylist) {
        
        let vc = R.storyboard.main.playlistViewController()!
        vc.viewModel = PlaylistViewModel(router: PlaylistRouter(owner: vc),
                                         provider: DefinedPlaylistProvider(playlist: playlist))
        
        sourceController?.navigationController?.pushViewController(vc, animated: true)
        
    }

    func showAddToPlaylist(for playlist: Playlist) {
        self.perform(segue: .showAddToPlaylist(playlist: playlist))
    }
}
