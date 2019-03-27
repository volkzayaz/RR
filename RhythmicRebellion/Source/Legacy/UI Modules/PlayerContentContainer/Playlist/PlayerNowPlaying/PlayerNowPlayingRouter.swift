//
//  PlayerNowPlayingRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerNowPlayingRouter: FlowRouter {
    var owner: UIViewController { get }
    func showAddToPlaylist(for tracks: [Track])
}

final class DefaultPlayerNowPlayingRouter:  PlayerNowPlayingRouter, FlowRouterSegueCompatible {
    
    var owner: UIViewController {
        return sourceController!
    }
    

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case showAddToPlaylist = "AddToPlaylistSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case showAddToPlaylist(tracks: [Track])

        var identifier: SegueDestinationList {
            switch self {
            case .showAddToPlaylist: return SegueList.showAddToPlaylist
            }
        }
    }

    private(set) var dependencies: RouterDependencies

    private(set) weak var viewModel: NowPlayingViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultPlayerNowPlayingRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .showAddToPlaylist(let tracks):
            guard let addToPlaylistViewController = (segue.destination as? UINavigationController)?.topViewController as? AddToPlaylistViewController else { fatalError("Incorrect controller for embedPlaylists") }
            let addToPlaylistRouter = DefaultAddToPlaylistRouter(dependencies: dependencies)
            addToPlaylistRouter.start(controller: addToPlaylistViewController, tracks: tracks)
            break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: NowPlayingViewController) {
        sourceController = controller
        let vm = NowPlayingViewModel(router: self,
                                     application: self.dependencies.application)
        controller.configure(viewModel: vm, router: self)
    }
    
    func showAddToPlaylist(for tracks: [Track]) {
        self.perform(segue: .showAddToPlaylist(tracks: tracks))
    }
}
