//
//  PlayerMyPlaylistsControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PlayerMyPlaylistsControllerViewModel: PlayerMyPlaylistsViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerMyPlaylistsViewModelDelegate?
    private(set) weak var router: PlayerMyPlaylistsRouter?

    private let application: Application
    private let player: Player
    private let restApiService: RestApiService

    private(set) var playlists: [FanPlaylist] = [FanPlaylist]()


    // MARK: - Lifecycle -

    deinit {
        self.application.removeObserver(self)
    }

    init(router: PlayerMyPlaylistsRouter, application: Application, player: Player, restApiService: RestApiService) {
        self.router = router
        self.application = application
        self.player = player
        self.restApiService = restApiService
    }

    func load(with delegate: PlayerMyPlaylistsViewModelDelegate) {
        self.delegate = delegate

        if (!(self.application.user?.isGuest ?? true)) {
            self.loadPlaylists()
            self.delegate?.reloadUI()
        }

        self.application.addObserver(self)
    }

    func reload() {
        if (!(self.application.user?.isGuest ?? true)) {
            self.loadPlaylists()
        }
    }

    func loadPlaylists() {
        self.restApiService.fanPlaylists(completion: { [weak self] (playlistsResult) in

            switch playlistsResult {
            case .success(let playlists):
                self?.playlists = playlists
                self?.delegate?.reloadUI()
            case .failure(let error):
                self?.delegate?.show(error: error, completion: { [weak self] in  self?.delegate?.reloadUI() })
            }
        })
    }

    func numberOfItems(in section: Int) -> Int {
        return self.playlists.count
    }

    func object(at indexPath: IndexPath) -> PlaylistItemCollectionViewCellViewModel? {
        guard indexPath.item < self.playlists.count else { return nil }

        return PlaylistItemViewModel(playlist: self.playlists[indexPath.item])
    }

    func selectObject(at indexPath: IndexPath) {
        self.router?.showContent(of: self.playlists[indexPath.item])
    }

    // MARK: Action support

    private func play(tracks: [Track]) {
        self.player.add(tracks: tracks, at: .next, completion: { [weak self] (playlistItems, error) in
            guard let playlistItem = playlistItems?.first else {
                guard let error = error else { return }
                self?.delegate?.show(error: error)
                return
            }

            self?.player.performAction(.playNow, for: playlistItem, completion: { [weak self] (error) in
                guard let error = error else { return }
                self?.delegate?.show(error: error)
            })
        })
    }

    private func addToPlayerPlaylist(tracks: [Track], at position: Player.PlaylistPosition) {
        self.player.add(tracks: tracks, at: position, completion: { [weak self] (playlistItems, error) in
            guard let error = error else { return }
            self?.delegate?.show(error: error)
        })
    }

    private func replacePlayerPlaylist(with tracks: [Track]) {

        self.player.replace(with: tracks, completion: { [weak self] (playlistItems, error) in
            guard let error = error else { return }
            self?.delegate?.show(error: error)
        })

    }

    private func clear(playlist: Playlist) {
        guard let fanPlaylist = playlist as? FanPlaylist else { return }

        self.restApiService.fanClear(playlist: fanPlaylist, completion: { [weak self] (error) in
            guard let error = error else { return }

            self?.delegate?.show(error: error)
        })
    }

    // MARK: - Playlist Actions -

    func actionTypes(for playlist: FanPlaylist) -> [PlaylistActionsViewModels.ActionViewModel.ActionType] {
        return [.playNow, .playNext, .playLast, .replaceCurrent, .toPlaylist, .delete]
    }

    func confirmation(for actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, with playlist: FanPlaylist) -> ConfirmationAlertViewModel.ViewModel? {

        switch actionType {
        case .clear: return ConfirmationAlertViewModel.Factory.makeClearPlaylistViewModel(actionCallback: { [weak self] (actionConfirmationType) in
            switch actionConfirmationType {
            case .ok: self?.performeAction(with: actionType, for: playlist)
            default: break
            }
        })

        case .delete: return ConfirmationAlertViewModel.Factory.makeDeletePlaylistViewModel(actionCallback: { [weak self] (actionConfirmationType) in
            switch actionConfirmationType {
            case .ok: self?.performeAction(with: actionType, for: playlist)
            default: break
            }
        })

        default: return nil
        }
    }

    func performeAction(with actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, for tracks: [Track]) {

        switch actionType {
        case .playNow: self.play(tracks: tracks)
        case .playNext: self.addToPlayerPlaylist(tracks: tracks, at: .next)
        case .playLast: self.addToPlayerPlaylist(tracks: tracks, at: .last)
        case .replaceCurrent: self.replacePlayerPlaylist(with: tracks)
        default: break
        }
    }

    func performeAction(with actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, for playlist: FanPlaylist) {

        switch actionType {
        case .playNow, .playNext, .playLast, .replaceCurrent:
            self.restApiService.fanTracks(for: playlist.id) { [weak self] (tracksResult) in
                switch tracksResult {
                case .success(let tracks): self?.performeAction(with: actionType, for: tracks)
                case .failure(let error): self?.delegate?.show(error: error)
                }
            }
        case .toPlaylist: self.router?.showAddToPlaylist(for: playlist)
        case .clear: self.clear(playlist: playlist)
        case .delete:
            self.application.delete(playlist: playlist) { [weak self] (error) in
                guard let error = error else { return }
                self?.delegate?.show(error: error)
            }
        case .cancel: break
        }
    }

    func isAction(with actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, availableFor playlist: FanPlaylist) -> Bool {
        switch actionType {
        case .playNow, .playNext, .playLast, .replaceCurrent: return true
        case .toPlaylist: return self.application.user?.isGuest == false
        case .delete: return playlist.isDefault == false
        case .clear: return false
        default: return true
        }
    }

    func actions(forObjectAt indexPath: IndexPath) -> PlaylistActionsViewModels.ViewModel? {
        guard indexPath.row < playlists.count else { return nil }
        let playlist = playlists[indexPath.row]

        let filteredPlaylistActionsTypes = self.actionTypes(for: playlist).filter {
            return self.isAction(with: $0, availableFor: playlist)
        }

        guard filteredPlaylistActionsTypes.count > 0 else { return nil }

        let playlistActions = PlaylistActionsViewModels.Factory().makeActionsViewModels(actionTypes: filteredPlaylistActionsTypes) { [weak self] (actionType) in
            guard let `self` = self else { return }
            guard let confirmationViewModel = self.confirmation(for: actionType, with: playlist) else {
                self.performeAction(with: actionType, for: playlist)
                return
            }

            self.delegate?.showConfirmation(confirmationViewModel: confirmationViewModel)
        }

        return PlaylistActionsViewModels.ViewModel(title: nil, message: nil, actions: playlistActions)
    }
}

extension PlayerMyPlaylistsControllerViewModel: ApplicationObserver {

    func application(_ application: Application, didChangeFanPlaylist fanPlaylistState: FanPlaylistState) {

        guard let playlist = self.playlists.filter( { return $0.id == fanPlaylistState.id } ).first,
            let playlistIndex = self.playlists.index(of: playlist) else {

                guard let updatedPlaylist = fanPlaylistState.playlist else { return }
                self.playlists.append(updatedPlaylist)
                self.delegate?.reloadUI()
                return
        }

        if let updatedPlaylist = fanPlaylistState.playlist {
            self.playlists[playlistIndex] = updatedPlaylist
        } else {
            self.playlists.remove(at: playlistIndex)
        }

        self.delegate?.reloadUI()
    }

}
