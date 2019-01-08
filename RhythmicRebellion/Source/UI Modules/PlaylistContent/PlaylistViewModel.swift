//
//  PlaylistViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import RxSwift

protocol PlaylistProvider: TrackProvider {
    var playlist: Playlist { get }
}

protocol DeletablePlaylistProvider: PlaylistProvider {
    func delete(track: Track, completion: @escaping (Box<Void>) -> Void)
}

struct FanPlaylistProvider: DeletablePlaylistProvider {
    
    let fanPlaylist: FanPlaylist
    var playlist: Playlist {
        return fanPlaylist
    }
    
    func provide(completion: @escaping (Box<[Track]>) -> Void) {
        
        return DataLayer.get.application.restApiService
            .fanTracks(for: playlist.id,
                       completion: Box<[Track]>.transformed(boxed: completion))
        
    }
    
    func delete(track: Track, completion: @escaping (Box<Void>) -> Void) {
        
        return DataLayer.get.application.restApiService
            .fanDelete(track,
                       from: fanPlaylist,
                       completion: { er in
                        
                        if let error = er { completion( .error(er:  error)) }
                        else              { completion( .value(val: ()   )) }
                            
            })
    }
    
}

struct DefinedPlaylistProvider: PlaylistProvider {
    
    let playlist: Playlist
    
    func provide(completion: @escaping (Box<[Track]>) -> Void) {
        
        return DataLayer.get.application.restApiService
            .tracks(for: playlist.id,
                    completion: Box<[Track]>.transformed(boxed: completion))
        
    }
    
}

struct AlbumPlaylistProvider: PlaylistProvider, Playlist {
    
    let album: Album
    
    func provide(completion: @escaping (Box<[Track]>) -> Void) {
        
        return ArtistRequest.albumRecords(album: album)
            .rx.response(type: ArtistResponse<Track>.self)
            .map { $0.data }
            .subscribe(onSuccess: { completion( .value(val: $0) )},
                       onError:   { completion( .error(er:  $0) )})
            .disposed(by: bag)
        
    }
    
    fileprivate let bag = DisposeBag()
    
    ///surrogate getter
    var playlist: Playlist {
        return self
    }
    
    var id: Int { return album.id }
    var name: String { return album.name }
    var isDefault: Bool { return false }
    var thumbnailURL: URL? { return nil }
    var description: String? { return nil }
    var title: String? { return nil }
    var isFanPlaylist: Bool { return false }
    
}

struct ArtistPlaylistProvider: PlaylistProvider {
    
    let artistPlaylist: ArtistPlaylist
    
    func provide(completion: @escaping (Box<[Track]>) -> Void) {
        
        return ArtistRequest.playlistRecords(playlist: artistPlaylist)
            .rx.response(type: ArtistResponse<Track>.self)
            .map { $0.data }
            .subscribe(onSuccess: { completion( .value(val: $0) )},
                       onError:   { completion( .error(er:  $0) )})
            .disposed(by: bag)
        
    }
    
    var playlist: Playlist {
        return artistPlaylist
    }
    fileprivate let bag = DisposeBag()
    
}

final class PlaylistViewModel {
    
    private var errorPresenter: ErrorPresenting {
        return tracksViewModel.delegate!
    }
    
    private var confirmationPresenter: ConfirmationPresenting {
        return tracksViewModel.delegate!
    }
    
    let tracksViewModel: TrackListViewModel
    var playlist: Playlist {
        return (tracksViewModel.trackProivder as! PlaylistProvider).playlist
    }
    
    private(set) weak var router: PlaylistContentRouter!
    private(set) weak var application: Application!
    private(set) weak var player: Player!
    
    private(set) weak var restApiService: RestApiService!
    
    let playlistHeaderViewModel: PlaylistHeaderViewModel
    
    // MARK: - Lifecycle -

    deinit {
        self.application?.removeWatcher(self)
    }

    init(router: PlaylistContentRouter,
         application: Application,
         player: Player,
         restApiService: RestApiService,
         audioFileLocalStorageService: AudioFileLocalStorageService,
         provider: PlaylistProvider) {
        
        self.router = router
        self.application = application
        self.player = player
        self.restApiService = restApiService
        
        let actions = { (list: TrackListViewModel,
                         track: Track,
                         indexPath: IndexPath) -> [ActionViewModel] in
            
            var result: [ActionViewModel] = []
            
            let maybeUser = application.user as? FanUser
            
            //////1
            
            if maybeUser?.isGuest == false {
                
                let toPlaylist = ActionViewModel(.toPlaylist) {
                    router.showAddToPlaylist(for: [track])
                }
                
                result.append(toPlaylist)
            }
            
            //////2
            
            if track.isPlayable {
            
                let playNow = ActionViewModel(.playNow) {
                    list.play(tracks: [track])
                }
                
                let playNext = ActionViewModel(.playNext) {
                    list.addToPlayerPlaylist(tracks: [track], at: .next)
                }
                
                let playLast = ActionViewModel(.playLast) {
                    list.addToPlayerPlaylist(tracks: [track], at: .last)
                }
            
                result.append(playNow)
                result.append(playNext)
                result.append(playLast)
            }
            
            /////3
            
            if let p = provider as? DeletablePlaylistProvider {
                
                let delete = ActionViewModel(.delete) {
                    
                    p.delete(track: track) { x in
                        switch x {
                        case .error(let error):
                            list.delegate?.show(error: error)
                            list.delegate?.reloadObjects(at: [indexPath])
                            
                        case .value(_):
                            list.loadItems()
                            
                        }
                    }
                    
                }
             
                result.append(delete)
                
            }
            
            return result
            
        }
        
        let select = { (list: TrackListViewModel,
                        track: Track,
                        indexPath: IndexPath) in
            
            guard track.isPlayable else {
                return
            }
            
            ///This piece of logic is still a mystery for me.
            ///Specifically, why is it different from same conditon present in NowPlayingViewModel
            let condition = !(player.currentItem?.playlistItem.track.id == track.id)
            
            if condition {
                list.play(tracks: [track])
                return
            }
            
            player.flipPlayState()
            
        }
        
        tracksViewModel = TrackListViewModel(application: application,
                                             player: player,
                                             audioFileLocalStorageService: audioFileLocalStorageService,
                                             dataProvider: provider,
                                             actionsProvider: actions,
                                             selectedProvider: select)
        
        playlistHeaderViewModel = PlaylistHeaderViewModel(playlist: provider.playlist,
                                                          isEmpty: tracksViewModel.isPlaylistEmpty)
    }

    func load(with delegate: TrackListBindings) {
        tracksViewModel.load(with: delegate)
        
        application.addWatcher(self)
    }

}

extension PlaylistViewModel {

    // MARK: Action support

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
        case .playNow: tracksViewModel.play(tracks: tracksViewModel.tracks)
        case .playNext: tracksViewModel.addToPlayerPlaylist(tracks: tracksViewModel.tracks, at: .next)
        case .playLast: tracksViewModel.addToPlayerPlaylist(tracks: tracksViewModel.tracks, at: .last)
        case .replaceCurrent: tracksViewModel.replacePlayerPlaylist(with: tracksViewModel.tracks)
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


extension PlaylistViewModel: ApplicationWatcher {

    func application(_ application: Application, didChangeFanPlaylist fanPlaylistState: FanPlaylistState) {
        guard let fanPlaylist = self.playlist as? FanPlaylist, fanPlaylist.id == fanPlaylistState.id else { return }
        guard let _ = fanPlaylistState.playlist else { self.router?.dismiss(); return }
        
        tracksViewModel.loadItems()
        
    }

}