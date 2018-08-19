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
    func showAddToPlaylist(for track: Track)
}

final class DefaultPlayerNowPlayingRouter:  PlayerNowPlayingRouter, SegueCompatible {

    typealias Destinations = SegueList

    enum SegueList: String, SegueDestinations {
        case showAddToPlaylist
        
        var identifier: String {
            switch self {
            case .showAddToPlaylist: return "showAddToPlaylist"
            }
        }
        
        static func from(identifier: String) -> SegueList? {
            switch identifier {
            case "showAddToPlaylist": return .showAddToPlaylist
            default: return nil
            }
        }
    }

    private(set) var dependencies: RouterDependencies

    private(set) weak var viewModel: PlayerNowPlayingViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let payload = merge(segue: segue, with: sender) else { return }

        switch payload {
        case .showAddToPlaylist:
            guard let addToPlaylistViewController = (segue.destination as? UINavigationController)?.topViewController as? AddToPlaylistViewController else { fatalError("Incorrect controller for embedPlaylists") }
            let addToPlaylistRouter = DefaultAddToPlaylistRouter(dependencies: dependencies)
            addToPlaylistRouter.start(controller: addToPlaylistViewController, track: sender as! Track)            
            break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: PlayerNowPlayingViewController) {
        sourceController = controller
        let vm = PlayerNowPlayingControllerViewModel(router: self, application: self.dependencies.application, player: self.dependencies.player)
        controller.configure(viewModel: vm, router: self)
    }
    
    func showAddToPlaylist(for track: Track) {
        self.sourceController?.performSegue(withIdentifier: "showAddToPlaylist", sender: track)
    }
}
