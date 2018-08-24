//
//  PlayerNowPlayingControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PlayerNowPlayingControllerViewModel: PlayerNowPlayingViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerNowPlayingViewModelDelegate?
    private(set) weak var router: PlayerNowPlayingRouter?
    private(set) weak var application: Application?
    private(set) weak var player: Player?

    private var tracks: [PlayerTrack] = [PlayerTrack]()

    // MARK: - Lifecycle -

    init(router: PlayerNowPlayingRouter, application: Application, player: Player) {
        self.router = router
        self.application = application
        self.player = player
    }

    func load(with delegate: PlayerNowPlayingViewModelDelegate) {
        self.delegate = delegate

        self.loadTracks()
        self.player?.addObserver(self)
    }

    func loadTracks() {
        self.tracks = self.player?.tracks ?? []
        self.delegate?.reloadUI()
    }

    func reload() {
        self.loadTracks()
    }

    func numberOfItems(in section: Int) -> Int {
        return self.tracks.count
    }

    func object(at indexPath: IndexPath) -> TrackViewModel? {
        guard indexPath.item < self.tracks.count else { return nil }
        
        var isCurrentInPlayer = false
        var isPlaying = false
        
        let track = self.tracks[indexPath.item]
        if let currentTrackId = player?.currentTrackId {
            isCurrentInPlayer = track.playlistItem.trackKey == currentTrackId.key
            isPlaying = isCurrentInPlayer && (player?.isPlaying ?? false)
        }

        return TrackViewModel(track: track.track, isCurrentInPlayer: isCurrentInPlayer, isPlaying: isPlaying)
    }
    
    func selectObject(at indexPath: IndexPath) {
        if let viewmodel = object(at: indexPath) {
            if !viewmodel.isCurrentInPlayer {
                self.player?.performAction(.playNow, for: self.tracks[indexPath.item], completion: nil)
            } else {
                if viewmodel.isPlaying {
                    player?.pause()
                } else {
                    player?.play()
                }
            }
        }
    }

    func isAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, availableFor track: PlayerTrack) -> Bool {
        switch actionType {
        case .toPlaylist: return self.application?.user?.isGuest == false
        case .replaceCurrent, .playNext, .playLast: return false
        case .delete: return self.tracks.count > 1
        default: return true
        }
    }

    func performeAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, for track: PlayerTrack) {
        switch actionType {
        case .playNow: self.player?.performAction(.playNow, for: track, completion: nil)
        case .delete: self.player?.performAction(.delete, for: track, completion: nil)
        case .toPlaylist:
            self.router?.showAddToPlaylist(for: track.track)
            break
        default: break
        }
    }
    
    func perform(action : PlayerNowPlayingTableHeaderView.Actions) {
        switch action {
        case .clear:
            self.player?.clearPlaylist()
        default:
            break
        }
    }

    func actions(forObjectAt indexPath: IndexPath) -> TrackActionsViewModels.ViewModel? {
        guard indexPath.row < self.tracks.count else { return nil }
        let track = self.tracks[indexPath.row]

        let filteredTrackActionsTypes = TrackActionsViewModels.allActionsTypes.filter {
            return self.isAction(with: $0, availableFor: track)
        }

        guard filteredTrackActionsTypes.count > 0 else { return nil }

        let trackActions = TrackActionsViewModels.Factory().makeActionsViewModels(actionTypes: filteredTrackActionsTypes) { [weak self, track] (actionType) in
            self?.performeAction(with: actionType, for: track)
        }

        return TrackActionsViewModels.ViewModel(title: nil,
                                                message: nil,
                                                actions: trackActions)

    }
}


extension PlayerNowPlayingControllerViewModel: PlayerObserver {
    
    func playerDidChangePlaylist(player: Player) {
        self.reload()
    }
    
    func player(player: Player, didChangeStatus status: PlayerStatus) {
        self.delegate?.reloadUI()
    }
    
    func player(player: Player, didChangePlayState isPlaying: Bool) {
        self.delegate?.reloadUI()
    }
    
    func player(player: Player, didChangePlayerQueueItem playerQueueItem: PlayerQueueItem) {
        self.delegate?.reloadUI()
    }
    
    func player(player: Player, didChangeBlockedState isBlocked: Bool) {
        self.delegate?.reloadUI()
    }
}
