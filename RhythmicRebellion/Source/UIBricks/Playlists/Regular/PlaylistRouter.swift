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
    
    var sourceController: UIViewController? { return owner }
    
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

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: PlaylistRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .showAddTracksToPlaylist(let tracks):
            guard let addToPlaylistViewController = (segue.destination as? UINavigationController)?.topViewController as? AddToPlaylistViewController else { fatalError("Incorrect controller for embedPlaylists") }
            let addToPlaylistRouter = AddToPlaylistRouter()
            addToPlaylistRouter.start(controller: addToPlaylistViewController, tracks: tracks)

        case .showAddPlaylistToPlaylist(let playlist):
            guard let addToPlaylistViewController = (segue.destination as? UINavigationController)?.topViewController as? AddToPlaylistViewController else { fatalError("Incorrect controller for embedPlaylists") }
            let addToPlaylistRouter = AddToPlaylistRouter()
            addToPlaylistRouter.start(controller: addToPlaylistViewController, playlist: playlist)
        }
    }


    weak var owner: UIViewController!
    init(owner: UIViewController) {
        self.owner = owner
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
