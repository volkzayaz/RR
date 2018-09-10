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

    private(set) var dependencies: RouterDependencies
    
    private(set) weak var viewModel: PlayerPlaylistRootViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultPlayerPlaylistRootRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .nowPlaying:
            guard let nowPlayingViewController = segue.destination as? PlayerNowPlayingViewController else { fatalError("Incorrect controller for PlayerNowPlayingViewControllerSegueIdentifier") }
            let nowPlayingRouter = DefaultPlayerNowPlayingRouter(dependencies: self.dependencies)
            nowPlayingRouter.start(controller: nowPlayingViewController)

        case .myPlaylists:
            guard let myPlaylistsViewController = segue.destination as? PlayerMyPlaylistsViewController else { fatalError("Incorrect controller for PlayerMyPlaylistsViewControllerSegueIdentifier") }
            let myPlaylistsRouter = DefaultPlayerMyPlaylistsRouter(dependencies: self.dependencies)
            myPlaylistsRouter.start(controller: myPlaylistsViewController)

        case .following:
            guard let followingViewController = segue.destination as? PlayerFollowingViewController else { fatalError("Incorrect controller for PlayerFollowingViewControllerSegueIdentifier") }
            let followingRouter = DefaultPlayerFollowingRouter(dependencies: self.dependencies)
            followingRouter.start(controller: followingViewController)

        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: PlayerPlaylistRootViewController) {
        sourceController = controller
        let vm = PlayerPlaylistRootControllerViewModel(router: self, application: dependencies.application)
        controller.configure(viewModel: vm, router: self)
    }
}
