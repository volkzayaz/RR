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

extension PlaylistProvider {
    var mode   : TrackViewModel.ThumbMode { return .index }
}

protocol DeletablePlaylistProvider: PlaylistProvider {
    func delete(track: Track) -> Maybe<Void>
    func drop() -> Maybe<Void> ///deletes whole playlist
}

protocol ClearablePlaylistProvider: PlaylistProvider {
    func clear() -> Maybe<Void>
}

protocol DownloadablePlaylistProvider: PlaylistProvider {
    
    var downloadable: Maybe<Downloadable> { get }
    
    var instantDownload: Bool { get }
}

struct FanPlaylistProvider: DeletablePlaylistProvider, ClearablePlaylistProvider {
    
    let fanPlaylist: FanPlaylist
    var playlist: Playlist {
        return fanPlaylist
    }
    
    func provide() -> Observable<[TrackRepresentation]> {
        return TrackRequest.fanTracks(playlistId: playlist.id)
            .rx.response(type: PlaylistTracksResponse.self)
            .map { $0.tracks.enumerated().map(TrackRepresentation.init) }
            .asObservable()
    }
    
    func delete(track: Track) -> Maybe<Void> {
        return PlaylistRequest.deleteTrack(track, from: fanPlaylist)
            .rx.emptyResponse()
    }
    
    func drop() -> Maybe<Void> {
        return PlaylistManager.delete(playlist: fanPlaylist)
    }
    
    func clear() -> Maybe<Void> {
        return PlaylistRequest.clear(playlist: fanPlaylist)
            .rx.emptyResponse()
    }
    
    
}

struct DefinedPlaylistProvider: PlaylistProvider {
    
    let playlist: Playlist
    
    func provide() -> Observable<[TrackRepresentation]> {
        return TrackRequest.tracks(playlistId: playlist.id)
            .rx.response(type: PlaylistTracksResponse.self)
            .map { $0.tracks.enumerated().map(TrackRepresentation.init) }
            .asObservable()
    }
    
}

struct AlbumPlaylistProvider: PlaylistProvider, Playlist, DownloadablePlaylistProvider {
    
    let album: Album
    let instantDownload: Bool
    
    func provide() -> Observable<[TrackRepresentation]> {
        return ArtistRequest.albumRecords(album: album)
            .rx.response(type: BaseReponse<[Track]>.self)
            .map { $0.data.enumerated().map(TrackRepresentation.init) }
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
 
    var downloadable: Maybe<Downloadable> {
        
        struct DownloadableAlbum: Downloadable {
            let fileName: String
            let url: URL
            func asURL() throws -> URL { return url }
        }
        
        let x = album.name
        return AlbumRequest.downloadLink(album: album)
            .rx.response(type: BaseReponse<String>.self)
            .map {
                DownloadableAlbum( fileName: "\(x).zip",
                                   url: URL(string: $0.data)! )
                
            }
        
    }
    
}

struct ArtistPlaylistProvider: PlaylistProvider {
    
    let artistPlaylist: ArtistPlaylist
    
    func provide() -> Observable<[TrackRepresentation]> {
        return ArtistRequest.playlistRecords(playlist: artistPlaylist)
            .rx.response(type: BaseReponse<[Track]>.self)
            .map { $0.data.enumerated().map(TrackRepresentation.init) }
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
            p.downloadable
                .silentCatch()
                .map { DownloadViewModel(downloadable: $0, instantStart: p.instantDownload) }
                .bind(to: downloadViewModel)
                .disposed(by: bag)
        }
        
        let actions = { (list: TrackListViewModel, t: TrackRepresentation) -> [RRSheet.Action] in
            
            var result: [RRSheet.Action] = []
            
            //////1

            if t.track.isPlayable {
                
                let playNow = RRSheet.Action(option: .playNow) {
                    Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: [t.track],
                                                                         style: .now))
                }
                
                let playNext = RRSheet.Action(option: .playNext) {
                    Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: [t.track],
                                                                         style: .next))
                }
                
                let playLast = RRSheet.Action(option: .playLater) {
                    Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: [t.track],
                                                                         style: .last))
                }
                
                result.append(playNow)
                result.append(playNext)
                result.append(playLast)
            }
            
            //////2
            
            if appStateSlice.user.isGuest == false {
                
                let toPlaylist = RRSheet.Action(option: .addToLibrary) {
                    router.showAddToPlaylist(for: [t.track])
                }
                
                result.append(toPlaylist)
            }
            
            /////3
            
            if let p = provider as? DeletablePlaylistProvider {
                
                let delete = RRSheet.Action(option: .delete) {
                    
                    let _ = p.delete(track: t.track)
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
    
    func trackSelected(track: Track) {
        guard track.isPlayable else {
            return
        }
        
        if appStateSlice.currentTrack?.track != track {
            Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: [track],
                                                                 style: .now))
            return
        }
        
        Dispatcher.dispatch(action: AudioPlayer.Switch())
    }
    
    func playNow() {
        Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: tracksViewModel.tracks.value.map { $0.track },
                                                             style: .now))
        
    }
    
    func showActions(sourceView: UIView, sourceRect: CGRect) {
        
        let tracks = tracksViewModel.tracks.value.map { $0.track }
        
        var actions = [
            RRSheet.Action(option: .playNext, action: {
                Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: tracks,
                                                                     style: .next))
            }),
            RRSheet.Action(option: .playLater, action: {
                Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: tracks,
                                                                     style: .last))
            }),
            RRSheet.Action(option: .replace, action: {
                Dispatcher.dispatch(action: ReplaceTracks(with: tracks))
            }),
            RRSheet.Action(option: .addToLibrary, action: {
                self.router?.showAddToPlaylist(for: self.playlist)
            }),
        ]
        
        let provider = (tracksViewModel.trackProivder as! PlaylistProvider)
        
        if let x = provider as? DeletablePlaylistProvider {
            actions.append(RRSheet.Action(option: .delete) { [unowned self] in
                let _ = x.drop()
                    .silentCatch(handler: self.router.owner)
                    .subscribe()
            })
        }
        
        if let x = provider as? ClearablePlaylistProvider {
            actions.append(RRSheet.Action(option: .clear) { [unowned self] in
                let _ = x.clear()
                    .silentCatch(handler: self.router.owner)
                    .subscribe(onNext: { [weak self] in
                        self?.tracksViewModel.dropAllTracks()
                    })
            })
        }

        router.showActions(actions: actions, sourceRect: sourceRect, sourceView: sourceView)
        
    }
    
}
