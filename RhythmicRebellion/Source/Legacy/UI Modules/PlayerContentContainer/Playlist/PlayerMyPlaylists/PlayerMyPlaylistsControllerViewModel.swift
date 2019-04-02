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
    private let restApiService: RestApiService

    private(set) var playlists: [FanPlaylist] = [FanPlaylist]()
    private(set) var playlistsActivities: [Int : Int] = [Int : Int]()

    // MARK: - Lifecycle -

    deinit {
        self.application.removeWatcher(self)
    }

    init(router: PlayerMyPlaylistsRouter, application: Application, restApiService: RestApiService) {
        self.router = router
        self.application = application
        self.restApiService = restApiService
    }

    func load(with delegate: PlayerMyPlaylistsViewModelDelegate) {
        self.delegate = delegate

        if (!(appStateSlice.user?.isGuest ?? true)) {
            self.loadPlaylists()
            self.delegate?.reloadUI()
        }

        self.application.addWatcher(self)
    }

    func reload() {
        if (!(appStateSlice.user?.isGuest ?? true)) {
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

        let playlist = self.playlists[indexPath.item]

        return PlaylistItemViewModel(playlist: playlist, showActivity: self.playlistsActivities[playlist.id] ?? 0 > 0)
    }

    func selectObject(at indexPath: IndexPath) {
        self.router?.showContent(of: self.playlists[indexPath.item])
    }

    private func increaseActivity(for playlist: Playlist) {
        guard let playlistActivityCounter = self.playlistsActivities[playlist.id] else {
            self.playlistsActivities[playlist.id] = 1
            return
        }

        self.playlistsActivities[playlist.id] = playlistActivityCounter + 1
    }

    private func decreaseActivity(for playlist: Playlist) {
        guard let playlistActivityCounter = self.playlistsActivities[playlist.id] else { return }
        guard playlistActivityCounter > 1 else { self.playlistsActivities[playlist.id] = nil; return }

        self.playlistsActivities[playlist.id] = playlistActivityCounter - 1
    }

    // MARK: Action support

    private func play(tracks: [Track]) {
        Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: tracks, style: .next))
    }
    
    private func addToPlayerPlaylist(tracks: [Track], at position: RRPlayer.AddStyle) {
        Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: tracks, style: position))
    }
    
    private func replacePlayerPlaylist(with tracks: [Track]) {
        Dispatcher.dispatch(action: ReplaceTracks(with: tracks))
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

    func confirmation(for actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, with playlist: FanPlaylist, with playlistItems: [Track]) -> ConfirmationAlertViewModel.ViewModel? {

        switch actionType {
        case .clear: return ConfirmationAlertViewModel.Factory.makeClearPlaylistViewModel(actionCallback: { [weak self] (actionConfirmationType) in
            switch actionConfirmationType {
            case .ok: self?.performeAction(with: actionType, for: playlist, with: playlistItems)
            default: break
            }
        })

        case .delete: return ConfirmationAlertViewModel.Factory.makeDeletePlaylistViewModel(actionCallback: { [weak self] (actionConfirmationType) in
            switch actionConfirmationType {
            case .ok: self?.performeAction(with: actionType, for: playlist, with: playlistItems)
            default: break
            }
        })

        default: return nil
        }
    }


    func performeAction(with actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, for playlist: FanPlaylist, with playlistItems: [Track]) {

        switch actionType {
        case .playNow: self.play(tracks: playlistItems)
        case .playNext: self.addToPlayerPlaylist(tracks: playlistItems, at: .next)
        case .playLast: self.addToPlayerPlaylist(tracks: playlistItems, at: .last)
        case .replaceCurrent: self.replacePlayerPlaylist(with: playlistItems)
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

    func isAction(with actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, availableFor playlist: FanPlaylist, with playlistItems: [Track]) -> Bool {
        switch actionType {
        case .playNow, .playNext, .playLast, .replaceCurrent: return playlistItems.isEmpty == false
        case .toPlaylist: return appStateSlice.user?.isGuest == false && playlistItems.isEmpty == false
        case .delete: return playlist.isDefault == false
        case .clear: return false
        default: return true
        }
    }

    func actions(forObjectAt indexPath: IndexPath,
                 completion: @escaping (IndexPath, PlaylistActionsViewModels.ViewModel) -> Void) {
        guard indexPath.row < playlists.count else { return }
        let playlist = playlists[indexPath.row]

        self.increaseActivity(for: playlist)
        self.delegate?.reloadItem(at: indexPath,completion: nil)

        self.restApiService.fanTracks(for: playlist.id) { [weak self] (tracksResult) in

            guard let self = self else { return }
            guard let playlistIndex = self.playlists.index(of: playlist) else { self.playlistsActivities[playlist.id] = nil; return }

            let playlistIndexPath = IndexPath(item: playlistIndex, section: 0)
            self.decreaseActivity(for: playlist)

            switch tracksResult {
            case .success(let tracks):

                let filteredPlaylistActionsTypes = self.actionTypes(for: playlist).filter {
                    return self.isAction(with: $0, availableFor: playlist, with: tracks)
                }

                let playlistActions = PlaylistActionsViewModels.Factory().makeActionsViewModels(actionTypes: filteredPlaylistActionsTypes) { [weak self] (actionType) in
                    guard let self = self else { return }
                    guard let confirmationViewModel = self.confirmation(for: actionType, with: playlist, with: tracks) else {
                        self.performeAction(with: actionType, for: playlist, with: tracks)
                        return
                    }

                    self.delegate?.showConfirmation(confirmationViewModel: confirmationViewModel)
                }

                let title = filteredPlaylistActionsTypes.isEmpty ? playlist.name : nil
                let message = filteredPlaylistActionsTypes.isEmpty ? NSLocalizedString("No actions available", comment: "Empty playlist actions message") : nil

                self.delegate?.reloadItem(at: playlistIndexPath, completion: {
                    completion(playlistIndexPath, PlaylistActionsViewModels.ViewModel(title: title, message: message, actions: playlistActions))
                })


            case .failure(let error):
                self.delegate?.reloadItem(at: playlistIndexPath, completion: nil)
                self.delegate?.show(error: error)
            }

        }
    }
}

extension PlayerMyPlaylistsControllerViewModel: ApplicationWatcher {

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
