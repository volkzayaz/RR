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
import RxCocoa
import RxDataSources

protocol PlaylistProvider: TrackProvider {
    var playlist: Playlist { get }
}

protocol DeletablePlaylistProvider: PlaylistProvider {
    func delete(track: Track) -> Maybe<Void>
}

protocol DownloadablePlaylistProvider: PlaylistProvider {
    
    var downloadURL: Maybe<String> { get }
    
    var instantDownload: Bool { get }
}

struct FanPlaylistProvider: DeletablePlaylistProvider {
    
    let fanPlaylist: FanPlaylist
    var playlist: Playlist {
        return fanPlaylist
    }
    
    func provide() -> Observable<[TrackProvidable]> {
        return TrackRequest.fanTracks(playlistId: playlist.id)
            .rx.response(type: PlaylistTracksResponse.self)
            .map { $0.tracks }
            .asObservable()
    }
    
    func delete(track: Track) -> Maybe<Void> {
        return PlaylistRequest.deleteTrack(track, from: fanPlaylist)
            .rx.emptyResponse()
    }
    
}

struct DefinedPlaylistProvider: PlaylistProvider {
    
    let playlist: Playlist
    
    func provide() -> Observable<[TrackProvidable]> {
        return TrackRequest.tracks(playlistId: playlist.id)
            .rx.response(type: PlaylistTracksResponse.self)
            .map { $0.tracks }
            .asObservable()
    }
    
}

struct AlbumPlaylistProvider: PlaylistProvider, Playlist, DownloadablePlaylistProvider {
    
    let album: Album
    let instantDownload: Bool
    
    func provide() -> Observable<[TrackProvidable]> {
        return ArtistRequest.albumRecords(album: album)
            .rx.response(type: BaseReponse<[Track]>.self)
            .map { $0.data }
            .asObservable()
    }
    
    ///surrogate getter
    var playlist: Playlist {
        return self
    }
    
    var id: Int { return album.id }
    var name: String { return album.name }
    var thumbnailURL: URL? {
        guard let x = album.image.simpleURL else { return nil }
            
        return URL(string: x)
    }

    var isDefault: Bool { return false }
    var description: String? { return nil }
    var title: String? { return nil }
    var isFanPlaylist: Bool { return false }
 
    var downloadURL: Maybe<String> {
        
        return AlbumRequest.downloadLink(album: album)
            .rx.response(type: BaseReponse<String>.self)
            .map { $0.data }
            
            
    }
    
}

struct ArtistPlaylistProvider: PlaylistProvider {
    
    let artistPlaylist: ArtistPlaylist
    
    func provide() -> Observable<[TrackProvidable]> {
        return ArtistRequest.playlistRecords(playlist: artistPlaylist)
            .rx.response(type: BaseReponse<[Track]>.self)
            .map { $0.data }
            .asObservable()
    }
    
    var playlist: Playlist {
        return artistPlaylist
    }
    
}

extension PlaylistViewModel {
    
    var downloadButtonHidden: Driver<Bool> {
        return downloadViewModel.asDriver().map { $0 == nil }
    }
    
    var downloadViewModelDriver: Driver<DownloadViewModel> {
        return downloadViewModel.asDriver().notNil()
    }
    
    var dataSource: Driver<[AnimatableSectionModel<String, TrackViewModel>]> {
        return tracksViewModel.trackViewModels.map { x in
            return [AnimatableSectionModel(model: "", items: x)]
        }
    }
    
}

final class PlaylistViewModel {
    
    let tracksViewModel: TrackListViewModel
    var playlist: Playlist {
        return (tracksViewModel.trackProivder as! PlaylistProvider).playlist
    }
    
    private(set) weak var router: PlaylistRouter!
    
    let headerViewModel: PlaylistHeaderViewModel
    
    let downloadViewModel = BehaviorRelay<DownloadViewModel?>(value: nil)
    fileprivate let bag = DisposeBag()
    
    // MARK: - Lifecycle -

    init(router: PlaylistRouter,
         provider: PlaylistProvider) {
        
        self.router = router
        
        if let p = provider as? DownloadablePlaylistProvider {
            p.downloadURL
                .silentCatch()
                .map { DownloadViewModel(remoteURL: $0, instantStart: p.instantDownload) }
                .bind(to: downloadViewModel)
                .disposed(by: bag)
        }
        
        let actions = { (list: TrackListViewModel, t: TrackProvidable) -> [ActionViewModel] in
            
            var result: [ActionViewModel] = []
            
            let user = appStateSlice.user
            
            //////1

            if t.track.isPlayable {
                
                let playNow = ActionViewModel(.playNow) {
                    DataLayer.get.daPlayer.add(tracks: [t.track], type: .now)
                }
                
                let playNext = ActionViewModel(.playNext) {
                    DataLayer.get.daPlayer.add(tracks: [t.track], type: .next)
                }
                
                let playLast = ActionViewModel(.playLast) {
                    DataLayer.get.daPlayer.add(tracks: [t.track], type: .last)
                }
                
                result.append(playNow)
                result.append(playNext)
                result.append(playLast)
            }
            
            //////2
            
            if user.isGuest == false {
                
                let toPlaylist = ActionViewModel(.toPlaylist) {
                    router.showAddToPlaylist(for: [t.track])
                }
                
                result.append(toPlaylist)
            }
            
            /////3
            
            if let p = provider as? DeletablePlaylistProvider {
                
                let delete = ActionViewModel(.delete) {
                    
                    p.delete(track: t.track)
                        .silentCatch(handler: router.owner)
                        .subscribe(onNext: {
                            list.drop(track: t)
                        })
                    
                }
             
                result.append(delete)
                
            }
            
            return result
            
        }
        
        tracksViewModel = TrackListViewModel(dataProvider: provider,
                                             router: TrackListRouter(owner: router.owner),
                                             actionsProvider: actions)
        
        headerViewModel = PlaylistHeaderViewModel(playlist: provider.playlist,
                                                          isEmpty: tracksViewModel.isPlaylistEmpty)
    }
    
    func openIn(sourceRect: CGRect, sourceView: UIView) {
        
        guard let data = downloadViewModel.value?.dataState.value,
            case .data(let url) = data else {
                return fatalErrorInDebug("Trying to `open in` album \(playlist.name) that hasn't been downloaded yet")
        }
        
        router.showOpenIn(url: url, sourceRect: sourceRect, sourceView: sourceView)
        
    }
    
}

extension PlaylistViewModel {

    // MARK: Action support

    private func clear(playlist: Playlist) {
        
        guard let fanPlaylist = playlist as? FanPlaylist else { return }

        PlaylistRequest.clear(playlist: fanPlaylist)
            .rx.emptyResponse()
            .silentCatch(handler: router.owner)
            .subscribe(onNext: { [weak self] in
                self?.tracksViewModel.dropAllTracks()
            })
        
    }
    
    func trackSelected(track: Track) {
        guard track.isPlayable else {
            return
        }
        
        if appStateSlice.currentTrack?.track != track {
            DataLayer.get.daPlayer.add(tracks: [track], type: .now)
            return
        }
        
        DataLayer.get.daPlayer.flip()
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

        let tracks = tracksViewModel.tracks.value.map { $0.track }
        
        switch actionType {
        case .playNow:
            DataLayer.get.daPlayer.add(tracks: tracks, type: .now)
            
        case .playNext:
            DataLayer.get.daPlayer.add(tracks: tracks, type: .next)
            
        case .playLast:
            DataLayer.get.daPlayer.add(tracks: tracks, type: .last)
            
        case .replaceCurrent:
            Dispatcher.dispatch(action: ReplaceTracks(with: tracks))
            
        case .toPlaylist: self.router?.showAddToPlaylist(for: playlist)
        case .clear: self.clear(playlist: playlist)

        case .delete:
            guard let fanPlaylist = self.playlist as? FanPlaylist, fanPlaylist.isDefault == false else { return }

            PlaylistManager.delete(playlist: fanPlaylist)
                .silentCatch(handler: router.owner)
                .subscribe()
            
        case .cancel: break
        }
    }

    func isAction(with actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, availableFor playlist: Playlist) -> Bool {
        switch actionType {
        case .playNow, .playNext, .playLast, .replaceCurrent: return self.tracksViewModel.isPlaylistEmpty == false
        case .toPlaylist: return appStateSlice.user.isGuest == false && self.tracksViewModel.isPlaylistEmpty == false
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

            self.router.owner.showConfirmation(confirmationViewModel: confirmationViewModel)
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

        router.owner.showConfirmation(confirmationViewModel: confirmationViewModel)
    }
    
}


extension PlaylistViewModel {

    func application( didChangeFanPlaylist fanPlaylistState: FanPlaylistState) {
        guard let fanPlaylist = self.playlist as? FanPlaylist, fanPlaylist.id == fanPlaylistState.id else { return }
        guard let _ = fanPlaylistState.playlist else { self.router?.dismiss(); return }
        
        tracksViewModel.dropAllTracks()
        
    }

}