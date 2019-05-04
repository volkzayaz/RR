//
//  PlaylistRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class PlaylistRouter: FlowRouterSegueCompatible {
    
    var owner: UIViewController {
        return sourceController!
    }
    
    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case addTracksToPlaylist = "AddToPlaylistSegueIdentifier"
        case addPlaylistToPlaylist = "AttachPlaylistToPlaylistSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case showAddTracksToPlaylist(tracks: [Track])
        case showAddPlaylistToPlaylist(playlist: Playlist)

        var identifier: SegueDestinationList {
            switch self {
            case .showAddTracksToPlaylist: return SegueList.addTracksToPlaylist
            case .showAddPlaylistToPlaylist: return SegueList.addPlaylistToPlaylist
            }
        }
    }

    private(set) var dependencies: RouterDependencies

    private(set) weak var viewModel: PlaylistViewModel?
    weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: PlaylistRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .showAddTracksToPlaylist(let tracks):
            guard let addToPlaylistViewController = (segue.destination as? UINavigationController)?.topViewController as? AddToPlaylistViewController else { fatalError("Incorrect controller for embedPlaylists") }
            let addToPlaylistRouter = AddToPlaylistRouter(dependencies: dependencies)
            addToPlaylistRouter.start(controller: addToPlaylistViewController, tracks: tracks)

        case .showAddPlaylistToPlaylist(let playlist):
            guard let addToPlaylistViewController = (segue.destination as? UINavigationController)?.topViewController as? AddToPlaylistViewController else { fatalError("Incorrect controller for embedPlaylists") }
            let addToPlaylistRouter = AddToPlaylistRouter(dependencies: dependencies)
            addToPlaylistRouter.start(controller: addToPlaylistViewController, playlist: playlist)
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: PlaylistContentViewController, playlist: Playlist) {
        sourceController = controller

        ////TODO: decouple the code further
        let provider: PlaylistProvider
        
        if let x = playlist as? FanPlaylist {
            provider = FanPlaylistProvider(fanPlaylist: x)
        }
        else {
            provider = DefinedPlaylistProvider(playlist: playlist)
        }
        
        let vm = PlaylistViewModel(router: self,
                                   provider: provider)

        controller.configure(viewModel: vm, router: self)
    }
    
    func showAddToPlaylist(for tracks: [Track]) {
        self.perform(segue: .showAddTracksToPlaylist(tracks: tracks))
    }

    func showAddToPlaylist(for playlist: Playlist) {
        self.perform(segue: .showAddPlaylistToPlaylist(playlist: playlist))
    }

    func dismiss() {
        self.sourceController?.navigationController?.popViewController(animated: true)
    }
    
    func showOpenIn(url: URL, sourceRect: CGRect, sourceView: UIView) {
        
        let activityViewController = UIActivityViewController(activityItems: [url],
                                                              applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceView = sourceView
        activityViewController.popoverPresentationController?.sourceRect = sourceRect
        
        owner.present(activityViewController, animated: true, completion: nil)
    }
    
}
