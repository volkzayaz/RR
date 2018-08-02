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
}

final class DefaultHomeRouter:  HomeRouter, SegueCompatible {

    typealias Destinations = SegueList

    enum SegueList: String, SegueDestinations {
        case playlistContentSegueIdentifier

        var identifier: String {
            switch self {
            case .playlistContentSegueIdentifier: return "PlaylistContentSegueIdentifier"
            }
        }

        static func from(identifier: String) -> SegueList? {
            switch identifier {
            case "PlaylistContentSegueIdentifier": return .playlistContentSegueIdentifier
            default: return nil
            }
        }
    }

    private(set) var dependencies: RouterDependencies
    
    private(set) weak var viewModel: HomeViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let payload = merge(segue: segue, with: sender) else { return }

        switch payload {
        case .playlistContentSegueIdentifier:
            guard let playlist = sender as? Playlist else { fatalError("Incorrect sender for PlaylistContentSegueIdentifier") }
            guard let playlistContentViewController = segue.destination as? PlaylistContentViewController else { fatalError("Incorrect controller for PlaylistContentSegueIdentifier") }
            let playlistContentRouter = DefaultPlaylistContentRouter(dependencies: self.dependencies)
            playlistContentRouter.start(controller: playlistContentViewController, playlist: playlist)
            break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: HomeViewController) {
        sourceController = controller
        let vm = HomeControllerViewModel(router: self, restApiService: self.dependencies.restApiService)
        controller.configure(viewModel: vm, router: self)
    }
}
