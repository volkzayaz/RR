//
//  PlaylistContentControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import Alamofire

final class PlaylistContentControllerViewModel: PlaylistContentViewModel {
    // MARK: - Private properties -

    private(set) weak var delegate: PlaylistContentViewModelDelegate?
    private(set) weak var router: PlaylistContentRouter?
    private(set) weak var application: Application?
    private(set) weak var player: Player?
    private(set) weak var restApiService: RestApiService?
    private(set) var trackPreviewOptionsImageGenerator: TrackPreviewOptionsImageGenerator
    private(set) var trackPriceFormatter: MoneyFormatter

    private var playlist: PlaylistShortInfo
    private var playlistTracks: [Track] = [Track]()

    var playlistHeaderViewModel: PlaylistHeaderViewModel { return PlaylistHeaderViewModel(playlist: self.playlist) }

    // MARK: - Lifecycle -

    init(router: PlaylistContentRouter, application: Application, player: Player, restApiService: RestApiService, playlist: PlaylistShortInfo) {
        self.router = router
        self.application = application
        self.player = player
        
        self.restApiService = restApiService

        self.playlist = playlist
        self.trackPreviewOptionsImageGenerator = TrackPreviewOptionsImageGenerator(font: UIFont.systemFont(ofSize: 7.0))

        self.trackPriceFormatter = MoneyFormatter()
    }

    func load(with delegate: PlaylistContentViewModelDelegate) {
        self.delegate = delegate

        self.loadTracks()
        self.delegate?.reloadUI()
        self.player?.addObserver(self)
    }

    func loadTracks() {
        let processResults: (Result<[Track]>) -> Void = { [weak self] (tracksResult) in
            switch tracksResult {
            case .success(let tracks):
                self?.playlistTracks = tracks
                self?.delegate?.reloadUI()
            case .failure(let error):
                self?.delegate?.show(error: error, completion: { [weak self] in self?.delegate?.reloadUI() })
            }
        }
        if self.playlist.isFanPlaylist {
            self.restApiService?.fanTracks(for: self.playlist.id, completion: processResults)
        } else {
            self.restApiService?.tracks(for: self.playlist.id, completion: processResults)
        }
    }

    func reload() {
        self.loadTracks()
    }

    func numberOfItems(in section: Int) -> Int {
        return self.playlistTracks.count
    }

    func object(at indexPath: IndexPath) -> TrackViewModel? {
        guard indexPath.item < self.playlistTracks.count else { return nil }

        var isCurrentInPlayer = false
        var isPlaying = false
        
        let track = self.playlistTracks[indexPath.item]
        let isCensorship = self.application?.user?.isCensorshipTrack(track) ?? track.isCensorship
        let previewOptionsImage = trackPreviewOptionsImageGenerator.image(for: track,
                                                                          trackTotalPlayMSeconds: self.player?.totalPlayMSeconds(for: track),
                                                                          user: self.application?.user)
        if let currentTrack = player?.currentItem?.playlistItem.track {
            isCurrentInPlayer = track.id == currentTrack.id
            isPlaying = isCurrentInPlayer && (player?.isPlaying ?? false)
        }
        
        return TrackViewModel(track: track, isCurrentInPlayer: isCurrentInPlayer, isPlaying: isPlaying, isCensorship: isCensorship, previewOptionsImage: previewOptionsImage)
    }
    
    func selectObject(at indexPath: IndexPath) {
        guard let viewModel = object(at: indexPath), viewModel.isPlayable else { return }

        if !viewModel.isCurrentInPlayer {
            play(track: self.playlistTracks[indexPath.item])
        } else {
            if viewModel.isPlaying {
                player?.pause()
            } else {
                player?.play()
            }
        }
    }

    func isAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, availableFor track: Track) -> Bool {
        switch actionType {
        case .forceToPlay:
            guard let fanUser = self.application?.user as? FanUser else { return false }
            return fanUser.isCensorshipTrack(track) && !fanUser.profile.forceToPlay.contains(track.id)
        case .doNotPlay:
            guard let fanUser = self.application?.user as? FanUser else { return false }
            return fanUser.isCensorshipTrack(track) && fanUser.profile.forceToPlay.contains(track.id)
        case .playNow, .playLast, .playNext: return track.isPlayable
        case .toPlaylist: return self.application?.user?.isGuest == false
        case .delete: return self.playlist.isFanPlaylist
        case .replaceCurrent: return false
        default: return true
        }
    }
    
    private func play(track: Track) {
        self.player?.add(track: track, at: .next, completion: { [weak self] (playerTrack, error) in
            guard error == nil, let trackToPlay = playerTrack else { return }
            self?.player?.performAction(.playNow, for: trackToPlay, completion: nil)
        })
    }

    func performeAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, for track: Track) {

        switch actionType {
        case .forceToPlay:
            self.application?.allowPlayTrackWithExplicitMaterial(track: track, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
        case .doNotPlay:
            self.application?.disallowPlayTrackWithExplicitMaterial(track: track, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
        case .playNow:
            self.play(track: track)
        case .playNext: self.player?.add(track: track, at: .next, completion: nil)
        case .playLast: self.player?.add(track: track, at: .last, completion: nil)
        case .toPlaylist:
            self.router?.showAddToPlaylist(for: track)
        case .delete:
            self.restApiService?.fanDelete(track, from: self.playlist, completion: { (error) in
                if let error = error {
                    self.delegate?.show(error: error)
                } else {
                    if let index = self.playlistTracks.index(of: track) {
                        self.playlistTracks.remove(at: index)
                        self.delegate?.reloadUI()
                    }
                }
            })
        default: break
        }
    }

    func actions(forObjectAt indexPath: IndexPath) -> TrackActionsViewModels.ViewModel? {
        guard indexPath.row < playlistTracks.count else { return nil }
        let track = playlistTracks[indexPath.row]

        var filteredTrackActionsTypes = TrackActionsViewModels.allActionsTypes.filter {
            return self.isAction(with: $0, availableFor: track)
        }

        if let trackPrice = track.price, let trackPriceString = self.trackPriceFormatter.string(from: trackPrice) {
            filteredTrackActionsTypes.append(.addToCart(trackPriceString))
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

extension PlaylistContentControllerViewModel: PlayerObserver {
    
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
