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
                self?.delegate?.show(error: error)
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
        if let currentTrack = player?.playerCurrentTrack {
            isCurrentInPlayer = track.id == currentTrack.id
            isPlaying = isCurrentInPlayer && (player?.isPlaying ?? false)
        }
        
        return TrackViewModel(track: track, isCurrentInPlayer: isCurrentInPlayer, isPlaying: isPlaying)
    }
    
    func selectObject(at indexPath: IndexPath) {
        if let viewmodel = object(at: indexPath) {
            if !viewmodel.isCurrentInPlayer {
                self.player?.performAction(.playNow, for: self.playlistTracks[indexPath.item], completion: nil)
            } else {
                if viewmodel.isPlaying {
                    player?.pause()
                } else {
                    player?.play()
                }
            }
        }
    }

    func isAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, availableFor track: Track) -> Bool {
        switch actionType {
        case .toPlaylist: return self.application?.user?.isGuest == false
        case .delete: return self.playlist.isFanPlaylist
        case .replaceCurrent: return false
        default: return true
        }
    }

    func performeAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, for track: Track) {

        switch actionType {
        case .playNow: self.player?.performAction(.add(.next), for: track, completion: { [weak self] (error) in
            guard  error == nil else { return }
            self?.player?.performAction(.playNow, for: track, completion: nil)
        })
        case .playNext: self.player?.performAction(.add(.next), for: track, completion: nil)
        case .playLast: self.player?.performAction(.add(.last), for: track, completion: nil)
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

        let filteredTrackActionsTypes = TrackActionsViewModels.allActionsTypes.filter {
            return self.isAction(with: $0, availableFor: track)
        }

        guard filteredTrackActionsTypes.count > 0 else { return nil }

        let trackActions = TrackActionsViewModels.Factory().makeActionsViewModels(actionTypes: filteredTrackActionsTypes) { [weak self, track] (actionType) in
            self?.performeAction(with: actionType, for: track)
        }

        return TrackActionsViewModels.ViewModel(title: NSLocalizedString("Actions", comment: "Actions title"),
                                                message: track.name,
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
