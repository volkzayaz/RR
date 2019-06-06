//
//  PlayerPlaylistRootRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/26/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerPlaylistRootRouter: FlowRouter {

}

final class DefaultPlayerPlaylistRootRouter:  PlayerPlaylistRootRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case nowPlaying = "PlayerNowPlayingViewControllerSegueIdentifier"
        case myPlaylists = "PlayerMyPlaylistsViewControllerSegueIdentifier"
        case following = "PlayerFollowingViewControllerSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case nowPlaying
        case myPlaylists
        case following

        var identifier: SegueDestinationList {
            switch self {
            case .nowPlaying: return SegueList.nowPlaying
            case .myPlaylists: return SegueList.myPlaylists
            case .following: return SegueList.following
            }
        }

        init?(destinationList: SegueDestinationList) {
            switch destinationList as? SegueList {
            case .nowPlaying?: self = .nowPlaying
            case .myPlaylists?: self = .myPlaylists
            case .following?: self = .following
            default: fatalError("UPS!")
            }
        }
    }

    
    
    private(set) var viewModel: PlayerPlaylistRootViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultPlayerPlaylistRootRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .nowPlaying:
            guard let nowPlayingViewController = segue.destination as? NowPlayingViewController else { fatalError("Incorrect controller for PlayerNowPlayingViewControllerSegueIdentifier") }
            let nowPlayingRouter = DefaultPlayerNowPlayingRouter()
            nowPlayingRouter.start(controller: nowPlayingViewController)

        case .myPlaylists:
            guard let x = segue.destination as? MyPlaylistsViewController else { fatalError("Incorrect controller for PlayerMyPlaylistsViewControllerSegueIdentifier") }
            
            x.viewModel = MyPlaylistsViewModel(router: MyPlaylistsRouter(owner: x))
            
        case .following:
            guard let x = segue.destination as? ArtistsFollowedViewController else {
                fatalError("Incorrect controller for PlayerFollowingViewControllerSegueIdentifier")
            }
            
            x.viewModel = ArtistsFollowedViewModel(router: ArtistsFollowedRouter(owner: x))
            
        }
    }

    func start(controller: PlayerPlaylistRootViewController) {
        sourceController = controller
        let vm = PlayerPlaylistRootViewModel(router: self)
        controller.configure(viewModel: vm, router: self)
    }
}
