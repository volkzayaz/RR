//
//  PlaylistContentControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PlaylistContentControllerViewModel: PlaylistContentViewModel {


    // MARK: - Private properties -

    private(set) weak var delegate: PlaylistContentViewModelDelegate?
    private(set) weak var router: PlaylistContentRouter?
    private(set) weak var application: Application?
    private(set) weak var player: Player?
    private(set) weak var restApiService: RestApiService?

    private var playlist: Playlist
    private var playlistTracks: [Track] = [Track]()    

    var playlistHeaderViewModel: PlaylistHeaderViewModel { return PlaylistHeaderViewModel(playlist: self.playlist) }

    // MARK: - Lifecycle -

    init(router: PlaylistContentRouter, application: Application, player: Player, restApiService: RestApiService, playlist: Playlist) {
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
    }

    func loadTracks() {
        self.restApiService?.tracks(for: self.playlist.id, completion: { [weak self] (tracksResult) in

            switch tracksResult {
            case .success(let tracks):
                self?.playlistTracks = tracks
                self?.delegate?.reloadUI()
            case .failure(let error):
                self?.delegate?.show(error: error)
            }
        })
    }

    func reload() {
        self.loadTracks()
    }

    func numberOfItems(in section: Int) -> Int {
        return self.playlistTracks.count
    }

    func object(at indexPath: IndexPath) -> TrackViewModel? {
        guard indexPath.item < self.playlistTracks.count else { return nil }

        return TrackViewModel(track: self.playlistTracks[indexPath.item])
    }

    func isAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, availableFor track: Track) -> Bool {
        switch actionType {
        case .toPlaylist: return self.application?.user?.isGuest == false
        case .replaceCurrent, .delete: return false
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
        case .toPlaylist: break
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
