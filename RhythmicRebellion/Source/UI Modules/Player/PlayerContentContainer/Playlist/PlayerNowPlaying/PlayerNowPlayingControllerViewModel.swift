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

    private var tracks: [Track] = [Track]()

    // MARK: - Lifecycle -

    init(router: PlayerNowPlayingRouter, application: Application, player: Player) {
        self.router = router
        self.application = application
        self.player = player
    }

    func load(with delegate: PlayerNowPlayingViewModelDelegate) {
        self.delegate = delegate

        self.loadTracks()
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

        return TrackViewModel(track: self.tracks[indexPath.item])
    }

    func isAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, availableFor track: Track) -> Bool {
        switch actionType {
        case .toPlaylist: return self.application?.user?.isGuest == false
        case .replaceCurrent, .playNext, .playLast: return false
        default: return true
        }
    }

    func performeAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, for track: Track) {

        switch actionType {
        case .playNow: self.player?.performAction(.playNow, for: track, completion: nil)
        case .delete: self.player?.performAction(.delete, for: track, completion: nil)
        case .toPlaylist: break
        default: break
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

        return TrackActionsViewModels.ViewModel(title: NSLocalizedString("Actions", comment: "Actions title"),
                                                message: track.name,
                                                actions: trackActions)

    }
}