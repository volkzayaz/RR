//
//  PlayerNowPlayingControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class PlayerNowPlayingControllerViewModel: PlayerNowPlayingViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerNowPlayingViewModelDelegate?
    private(set) weak var router: PlayerNowPlayingRouter?
    private(set) weak var application: Application?
    private(set) weak var player: Player?
    private(set) var trackPreviewOptionsImageGenerator: TrackPreviewOptionsImageGenerator

    private var tracks: [PlayerTrack] = [PlayerTrack]()

    // MARK: - Lifecycle -

    init(router: PlayerNowPlayingRouter, application: Application, player: Player) {
        self.router = router
        self.application = application
        self.player = player
        self.trackPreviewOptionsImageGenerator = TrackPreviewOptionsImageGenerator(font: UIFont.systemFont(ofSize: 8.0))
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
        let isCensorship = self.application?.user?.isCensorshipTrack(track.track) ?? track.track.isCensorship
        let previewOptionsImage = self.trackPreviewOptionsImageGenerator.image(for: track.track,
                                                                               trackTotalPlayMSeconds: self.player?.totalPlayMSeconds(for: track.track),
                                                                               user: self.application?.user)

        if let currentTrackId = player?.currentTrackId {
            isCurrentInPlayer = track.playlistItem.trackKey == currentTrackId.key
            isPlaying = isCurrentInPlayer && (player?.isPlaying ?? false)
        }

        return TrackViewModel(track: track.track, isCurrentInPlayer: isCurrentInPlayer, isPlaying: isPlaying, isCensorship: isCensorship, previewOptionsImage: previewOptionsImage)
    }
    
    func selectObject(at indexPath: IndexPath) {
        guard let viewModel = object(at: indexPath), viewModel.isPlayable else { return }

        if !viewModel.isCurrentInPlayer {
            self.player?.performAction(.playNow, for: self.tracks[indexPath.item], completion: nil)
        } else {
            if viewModel.isPlaying {
                player?.pause()
            } else {
                player?.play()
            }
        }
    }

    func isAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, availableFor track: PlayerTrack) -> Bool {
        switch actionType {
        case .forceToPlay:
            guard let fanUser = self.application?.user as? FanUser else { return false }
            return fanUser.isCensorshipTrack(track.track) && !fanUser.profile.forceToPlay.contains(track.track.id)
        case .doNotPlay:
            guard let fanUser = self.application?.user as? FanUser else { return false }
            return fanUser.isCensorshipTrack(track.track) && fanUser.profile.forceToPlay.contains(track.track.id)
        case .playNow: return track.track.isPlayable
        case .toPlaylist: return self.application?.user?.isGuest == false
        case .replaceCurrent, .playNext, .playLast: return false
        case .delete: return self.tracks.count > 1
        default: return true
        }
    }

    func performeAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, for track: PlayerTrack) {
        switch actionType {
        case .forceToPlay:
            self.application?.allowPlayTrackWithExplicitMaterial(track: track.track, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
        case .doNotPlay:
            self.application?.disallowPlayTrackWithExplicitMaterial(track: track.track, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
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
