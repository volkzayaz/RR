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

    private var playlistItems: [PlayerPlaylistItem] = [PlayerPlaylistItem]()

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
        self.playlistItems = self.player?.playlistItems ?? []
        self.delegate?.reloadUI()
    }

    func reload() {
        self.loadTracks()
    }

    func numberOfItems(in section: Int) -> Int {
        return self.playlistItems.count
    }

    func object(at indexPath: IndexPath) -> TrackViewModel? {
        guard indexPath.item < self.playlistItems.count else { return nil }
        
        var isCurrentInPlayer = false
        var isPlaying = false
        
        let playlistItem = self.playlistItems[indexPath.item]
        let isCensorship = self.application?.user?.isCensorshipTrack(playlistItem.track) ?? playlistItem.track.isCensorship
        let previewOptionsImage = self.trackPreviewOptionsImageGenerator.image(for: playlistItem.track,
                                                                               trackTotalPlayMSeconds: self.player?.totalPlayMSeconds(for: playlistItem.track),
                                                                               user: self.application?.user)

        if let currentPlaylistItem = player?.currentItem?.playlistItem {
            isCurrentInPlayer = playlistItem.playlistLinkedItem == currentPlaylistItem.playlistLinkedItem
            isPlaying = isCurrentInPlayer && (player?.isPlaying ?? false)
        }

        return TrackViewModel(track: playlistItem.track, isCurrentInPlayer: isCurrentInPlayer, isPlaying: isPlaying, isCensorship: isCensorship, previewOptionsImage: previewOptionsImage)
    }
    
    func selectObject(at indexPath: IndexPath) {
        guard let viewModel = object(at: indexPath), viewModel.isPlayable else { return }

        if !viewModel.isCurrentInPlayer {
            self.player?.performAction(.playNow, for: self.playlistItems[indexPath.item], completion: nil)
        } else {
            if viewModel.isPlaying {
                player?.pause()
            } else {
                player?.play()
            }
        }
    }

    func isAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, availableFor playlistItem: PlayerPlaylistItem) -> Bool {
        switch actionType {
        case .forceToPlay:
            guard let fanUser = self.application?.user as? FanUser else { return false }
            return fanUser.isCensorshipTrack(playlistItem.track) && !fanUser.profile.forceToPlay.contains(playlistItem.track.id)
        case .doNotPlay:
            guard let fanUser = self.application?.user as? FanUser else { return false }
            return fanUser.isCensorshipTrack(playlistItem.track) && fanUser.profile.forceToPlay.contains(playlistItem.track.id)
        case .playNow: return playlistItem.track.isPlayable
        case .toPlaylist: return self.application?.user?.isGuest == false
        case .replaceCurrent, .playNext, .playLast: return false
        case .delete: return self.playlistItems.count > 1
        default: return true
        }
    }

    func performeAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, for playlistItem: PlayerPlaylistItem) {
        switch actionType {
        case .forceToPlay:
            self.application?.allowPlayTrackWithExplicitMaterial(track: playlistItem.track, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
        case .doNotPlay:
            self.application?.disallowPlayTrackWithExplicitMaterial(track: playlistItem.track, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
        case .playNow: self.player?.performAction(.playNow, for: playlistItem, completion: nil)
        case .delete: self.player?.performAction(.delete, for: playlistItem, completion: nil)
        case .toPlaylist:
            self.router?.showAddToPlaylist(for: playlistItem.track)
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
        guard indexPath.row < self.playlistItems.count else { return nil }
        let playlistItem = self.playlistItems[indexPath.row]

        let filteredTrackActionsTypes = TrackActionsViewModels.allActionsTypes.filter {
            return self.isAction(with: $0, availableFor: playlistItem)
        }

        guard filteredTrackActionsTypes.count > 0 else { return nil }

        let trackActions = TrackActionsViewModels.Factory().makeActionsViewModels(actionTypes: filteredTrackActionsTypes) { [weak self, playlistItem] (actionType) in
            self?.performeAction(with: actionType, for: playlistItem)
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
