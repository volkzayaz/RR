//
//  HomeControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import Alamofire

final class HomeControllerViewModel: HomeViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: HomeViewModelDelegate?
    private(set) weak var router: HomeRouter?

    private(set) var application: Application
    private(set) var player: Player
    private(set) var restApiService: RestApiService

    private(set) var playlists: [DefinedPlaylist] = [DefinedPlaylist]()

    // MARK: - Lifecycle -

    init(router: HomeRouter, application: Application, player: Player, restApiService: RestApiService) {
        self.router = router
        self.application = application
        self.player = player
        self.restApiService = restApiService
    }

    func load(with delegate: HomeViewModelDelegate) {
        self.delegate = delegate

        self.loadPlaylists()

        self.delegate?.reloadUI()
    }

    func reload() {
        self.loadPlaylists()
    }

    func loadPlaylists() {

        self.restApiService.playlists { [weak self] (definedPlaylistsResult) in
            switch definedPlaylistsResult {
            case .success(let definedPlaylists):
                self?.playlists = definedPlaylists
                self?.delegate?.reloadUI()
            case .failure(let error):
                self?.delegate?.show(error: error, completion: { [weak self] in self?.delegate?.reloadUI() })
            }
        }
    }

    func numberOfItems(in section: Int) -> Int {
        return self.playlists.count
    }

    func object(at indexPath: IndexPath) -> PlaylistItemViewModel? {
        guard indexPath.item < self.playlists.count else { return nil }

        return PlaylistItemViewModel(playlist: self.playlists[indexPath.item])
    }

    func selectObject(at indexPath: IndexPath) {
        self.router?.showContent(of: self.playlists[indexPath.item])
    }


    // MARK: - Playlist Actions -

    func actionTypes(for playlist: DefinedPlaylist) -> [PlaylistActionsViewModels.ActionViewModel.ActionType] {
        return [.playNow, .playNext, .playLast, .toPlaylist, .replaceCurrent]
    }

    func confirmation(for actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, with playlist: DefinedPlaylist) -> ConfirmationAlertViewModel.ViewModel? {

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

    private func play(tracks: [Track]) {
        self.player.add(tracks: tracks, at: .next, completion: { [weak self] (playlistItems, error) in
            guard error == nil, let playlistItem = playlistItems?.first else { return }
            self?.player.performAction(.playNow, for: playlistItem, completion: nil)
        })
    }

    func performeAction(with actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, for tracks: [Track]) {

        switch actionType {
        case .playNow: self.play(tracks: tracks)
        case .playNext: self.player.add(tracks: tracks, at: .next, completion: nil)
        case .playLast: self.player.add(tracks: tracks, at: .last, completion: nil)
        case .toPlaylist: self.router?.showAddToPlaylist(for: tracks)
        case .replaceCurrent: self.player.replace(with: tracks, completion: nil)
        default: break
        }
    }

    func performeAction(with actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, for playlist: DefinedPlaylist) {

        switch actionType {
        case .playNow, .playNext, .playLast, .toPlaylist, .replaceCurrent:
            self.restApiService.tracks(for: playlist.id) { [weak self] (tracksResult) in
                switch tracksResult {
                case .success(let tracks): self?.performeAction(with: actionType, for: tracks)
                case .failure(let error): self?.delegate?.show(error: error)
                }
            }
        case .clear: break
        case .delete: break
        case .cancel: break
        }
    }

    func isAction(with actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, availableFor playlist: DefinedPlaylist) -> Bool {
        switch actionType {
        case .playNow, .playNext, .playLast, .toPlaylist, .replaceCurrent: return true
        case .delete: return false
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
