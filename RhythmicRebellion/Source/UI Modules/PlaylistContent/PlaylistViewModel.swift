//
//  PlaylistViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PlaylistViewModel {
    
    private var errorPresenter: ErrorPresenting {
        return tracksViewModel.delegate!
    }
    
    private var confirmationPresenter: ConfirmationPresenting {
        return tracksViewModel.delegate!
    }
    
    lazy var tracksViewModel = TrackListViewModel(application: application,
                                                  player: player,
                                                  audioFileLocalStorageService: audioFileLocalStorageService,
                                                  provider: self)
    
    private(set) weak var router: PlaylistContentRouter!
    private(set) weak var application: Application!
    private(set) weak var player: Player!
    private(set) weak var audioFileLocalStorageService: AudioFileLocalStorageService!
    
    private(set) weak var restApiService: RestApiService!
    
    private var playlist: Playlist

    var playlistHeaderViewModel: PlaylistHeaderViewModel {
        return PlaylistHeaderViewModel(playlist: playlist,
                                       isEmpty: tracksViewModel.isPlaylistEmpty)
    }

    // MARK: - Lifecycle -

    deinit {
        self.application?.removeWatcher(self)
    }

    init(router: PlaylistContentRouter,
         application: Application,
         player: Player,
         restApiService: RestApiService,
         audioFileLocalStorageService: AudioFileLocalStorageService,
         playlist: Playlist) {
        
        self.router = router
        self.application = application
        self.player = player
        self.restApiService = restApiService
        self.audioFileLocalStorageService = audioFileLocalStorageService
        
        self.playlist = playlist
        
    }

    func load(with delegate: TrackListBindings) {
        tracksViewModel.load(with: delegate)
        
        application.addWatcher(self)
    }

}

extension PlaylistViewModel: TrackProvider {
    
    func provide(completion: @escaping (Box<[Track]>) -> Void) {
        
        if playlist.isFanPlaylist {
            restApiService.fanTracks(for: playlist.id,
                                     completion: Box<[Track]>.transformed(boxed: completion))
        } else {
            restApiService.tracks(for: playlist.id,
                                  completion: Box<[Track]>.transformed(boxed: completion))
        }
        
    }
    
    func actions(for track: Track, indexPath: IndexPath) -> [ActionViewModel] {
    
        let maybeUser = application?.user as? FanUser
        
        let ftp = ActionViewModel(.forceToPlay) { [weak self] in
            self?.tracksViewModel.forceToPlay(track: track)
        }
        
        let dnp = ActionViewModel(.doNotPlay) { [weak self] in
            self?.tracksViewModel.doNotPlay(track: track)
        }
        
        let toPlaylist = ActionViewModel(.toPlaylist) { [weak self] in
            self?.router?.showAddToPlaylist(for: [track])
        }
        
        let delete = ActionViewModel(.delete) { [weak self] in

            self?.restApiService?.fanDelete(track,
                                            from: self?.playlist as! FanPlaylist,
                                            completion: { [weak self] er in
                
                if let error = er {
                    self?.errorPresenter.show(error: error)
                    self?.tracksViewModel.delegate?.reloadObjects(at: [indexPath])
                } else {
                    self?.tracksViewModel.loadItems()
                }
                
            })
            
        }
        
        let playNow = ActionViewModel(.playNow) { [weak self] in
            self?.play(tracks: [track])
        }
        
        let playNext = ActionViewModel(.playNext) { [weak self] in
            self?.addToPlayerPlaylist(tracks: [track], at: .next)
        }
        
        let playLast = ActionViewModel(.playLast) { [weak self] in
            self?.addToPlayerPlaylist(tracks: [track], at: .last)
        }
        
        //////
        var result: [ActionViewModel] = []
        
        if let user = maybeUser,
            user.isCensorshipTrack(track) &&
                !user.profile.forceToPlay.contains(track.id) {
            result.append(ftp)
        }
        
        if let user = maybeUser,
            user.isCensorshipTrack(track) &&
                user.profile.forceToPlay.contains(track.id) {
            result.append(dnp)
        }
        
        if track.isPlayable {
            result.append(playNow)
            result.append(playNext)
            result.append(playLast)
        }
        
        if application?.user?.isGuest == false {
            result.append(toPlaylist)
        }
        
        result.append(delete)
        
        if let user = maybeUser,
            user.hasPurchase(for: track) {
            ///No proper action is available so far
            //result.append(add)
        }
        
        return result
        
        
    }
    
    var selected: (Track, IndexPath) -> Void {
        
        return { [weak self] (track, _) in
            
            guard track.isPlayable else {
                return
            }
            
            ///This piece of logic is still a mystery for me.
            ///Specifically, why is it different from same conditon present in NowPlayingViewModel
            let condition = !(self?.player?.currentItem?.playlistItem.track.id == track.id)
            
            if condition {
                self?.play(tracks: [track])
                return
            }
            
            self?.player?.flipPlayState()
            
        }
        
    }
    
}

extension PlaylistViewModel {

    // MARK: Action support

    private func play(tracks: [Track]) {
        
        self.player?.add(tracks: tracks, at: .next, completion: { [weak self] (playlistItems, error) in
            guard let playlistItem = playlistItems?.first else {
                guard let error = error else { return }
                self?.errorPresenter.show(error: error)
                return
            }

            self?.player?.performAction(.playNow, for: playlistItem, completion: { [weak self] (error) in
                guard let error = error else { return }
                self?.errorPresenter.show(error: error)
            })
        })
    }

    private func addToPlayerPlaylist(tracks: [Track], at position: Player.PlaylistPosition) {
        guard tracks.isEmpty == false else { return }

        self.player?.add(tracks: tracks, at: position, completion: { [weak self] (playlistItems, error) in
            guard let error = error else { return }
            self?.errorPresenter.show(error: error)
        })
    }

    private func replacePlayerPlaylist(with tracks: [Track]) {
        guard tracks.isEmpty == false else { return }

        self.player?.replace(with: tracks, completion: { [weak self] (playlistItems, error) in
            guard let error = error else { return }
            self?.errorPresenter.show(error: error)
        })

    }

    private func clear(playlist: Playlist) {
        
        guard let fanPlaylist = playlist as? FanPlaylist else { return }

        self.restApiService?.fanClear(playlist: fanPlaylist) { [weak self] (error) in
            if let e = error {
                self?.errorPresenter.show(error: e)
            }
            
            self?.tracksViewModel.loadItems()
        }
        
    }
    
}

extension PlaylistViewModel {

    // MARK: - Playlist Actions -
    
    func actionTypes(for playlist: Playlist) -> [PlaylistActionsViewModels.ActionViewModel.ActionType] {
        switch playlist {
        case _ as FanPlaylist:
            return [.playNow, .playNext, .playLast, .replaceCurrent, .toPlaylist, .delete]
        case _ as DefinedPlaylist:
            return [.playNow, .playNext, .playLast, .toPlaylist, .replaceCurrent]
        default: return []
        }
    }

    func confirmation(for actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, with playlist: Playlist) -> ConfirmationAlertViewModel.ViewModel? {

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

    func performeAction(with actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, for playlist: Playlist) {

        switch actionType {
        case .playNow: self.play(tracks: tracksViewModel.tracks)
        case .playNext: self.addToPlayerPlaylist(tracks: tracksViewModel.tracks, at: .next)
        case .playLast: self.addToPlayerPlaylist(tracks: tracksViewModel.tracks, at: .last)
        case .replaceCurrent: self.replacePlayerPlaylist(with: tracksViewModel.tracks)
        case .toPlaylist: self.router?.showAddToPlaylist(for: playlist)
        case .clear: self.clear(playlist: playlist)

        case .delete:
            guard let fanPlaylist = self.playlist as? FanPlaylist, fanPlaylist.isDefault == false else { return }

            self.application?.delete(playlist: fanPlaylist, completion: { [weak self] (error) in
                guard let error = error else { return }
                
                self?.errorPresenter.show(error: error)
            })

        case .cancel: break
        }
    }

    func isAction(with actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, availableFor playlist: Playlist) -> Bool {
        switch actionType {
        case .playNow, .playNext, .playLast, .replaceCurrent: return self.tracksViewModel.isPlaylistEmpty == false
        case .toPlaylist: return self.application?.user?.isGuest == false && self.tracksViewModel.isPlaylistEmpty == false
        case .delete: return playlist.isFanPlaylist && playlist.isDefault == false
        case .clear: return false
        default: return true
        }
    }

    func filteredActionsTypes(for playlist: Playlist) -> [PlaylistActionsViewModels.ActionViewModel.ActionType] {
        return self.actionTypes(for: playlist).filter {
            self.isAction(with: $0, availableFor: self.playlist)
        }
    }

    func playlistActions() -> PlaylistActionsViewModels.ViewModel? {

        let filteredPlaylistActionsTypes = self.filteredActionsTypes(for: playlist)

        let playlistActions = PlaylistActionsViewModels.Factory().makeActionsViewModels(actionTypes: filteredPlaylistActionsTypes) { [weak self] (actionType) in
            guard let `self` = self else { return }
            guard let confirmationViewModel = self.confirmation(for: actionType, with: self.playlist) else {
                self.performeAction(with: actionType, for: self.playlist)
                return
            }

            self.confirmationPresenter.showConfirmation(confirmationViewModel: confirmationViewModel)
        }

        let title = filteredPlaylistActionsTypes.isEmpty ? playlist.name : nil
        let message = filteredPlaylistActionsTypes.isEmpty ? NSLocalizedString("No actions available", comment: "Empty playlist actions message") : nil

        return PlaylistActionsViewModels.ViewModel(title: title,
                                                   message: message,
                                                   actions: playlistActions)
    }

    func clearPlaylist() {
        guard let confirmationViewModel = self.confirmation(for: .clear, with: self.playlist) else {
            self.performeAction(with: .clear, for: self.playlist)
            return
        }

        self.confirmationPresenter.showConfirmation(confirmationViewModel: confirmationViewModel)
    }
    
}


extension PlaylistViewModel: ApplicationObserver {

    func application(_ application: Application, didChangeFanPlaylist fanPlaylistState: FanPlaylistState) {
        guard let fanPlaylist = self.playlist as? FanPlaylist, fanPlaylist.id == fanPlaylistState.id else { return }
        guard let _ = fanPlaylistState.playlist else { self.router?.dismiss(); return }
        
        tracksViewModel.loadItems()
        
    }

}
