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

final class DefaultPlayerPlaylistRootRouter:  PlayerPlaylistRootRouter, SegueCompatible {

    typealias Destinations = SegueList

    enum SegueList: String, SegueDestinations {
        case nowPlaying
        case myPlaylists
        case following

        var identifier: String {
            switch self {
            case .nowPlaying: return "PlayerNowPlayingViewControllerSegueIdentifier"
            case .myPlaylists: return "PlayerMyPlaylistsViewControllerSegueIdentifier"
            case .following: return "PlayerFollowingViewControllerSegueIdentifier"
            }
        }

        static func from(identifier: String) -> SegueList? {
            switch identifier {
            case "PlayerNowPlayingViewControllerSegueIdentifier": return .nowPlaying
            case "PlayerMyPlaylistsViewControllerSegueIdentifier": return .myPlaylists
            case "PlayerFollowingViewControllerSegueIdentifier": return .following
            default: return nil
            }
        }
    }

    private(set) var dependencies: RouterDependencies
    
    private(set) weak var viewModel: PlayerPlaylistRootViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let payload = merge(segue: segue, with: sender) else { return }

        switch payload {
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
        let vm = PlayerPlaylistRootControllerViewModel(router: self)
        controller.configure(viewModel: vm, router: self)
    }
}
