//
//  ArtistViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources

extension ArtistViewModel {
    
    var dataSource: Driver<[AnimatableSectionModel<String, Data>]> {
        
        return Driver.combineLatest(data.asDriver(), source.asDriver()) { (x, source) in
            guard x.count > 0 else { return [] }
            
            let subset = x[source.rawValue]
            
            return [AnimatableSectionModel(model: subset.0, items: subset.1)]
        }
    }
 
    var artistName: String {
        return artist.name
    }
    
    var artistCoverURL: String? {
        return artist.profileImage?.simpleURL
    }
    
    func title(for section: Int) -> String {
        return data.value[section].0.uppercased()
    }
    
}

struct ArtistViewModel : MVVM_ViewModel {
    
    let tracksViewModel: TrackListViewModel
    
    fileprivate let artist: Artist
    fileprivate let data = BehaviorRelay<[(String, [Data])]>(value: [])
    let source = BehaviorRelay<Source>(value: .albums)
    
    init(router: ArtistRouter, artist: Artist) {
        self.router = router
        self.artist = artist

        let actions: TrackListViewModel.ActionsProvider = { _, t in
            
            var result: [RRSheet.Action] = []
            
            //////1
            
            if t.track.isPlayable {
                
                result.append(RRSheet.Action(option: .playNow) {
                    Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: [t.track],
                                                                         style: .now))
                })
                
                result.append(RRSheet.Action(option: .playNext) {
                    Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: [t.track],
                                                                         style: .next))
                })
                
                result.append(RRSheet.Action(option: .playNext) {
                    Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: [t.track],
                                                                         style: .last))
                })
                
            }
            
            //////2
            
            if appStateSlice.user.isGuest == false {
                
                result.append(RRSheet.Action(option: .addToLibrary) {
                    router.showAddToPlaylist(for: [t.track])
                })
                
            }
            
            /////3
            
            
            return result
            
        }
        
        tracksViewModel = TrackListViewModel(
                                             dataProvider: TracksProvider(artist: artist),
                                             router: router.trackListRouter(),
                                             actionsProvider: actions)
        
        let albums = ArtistRequest.albums(artist: artist)
            .rx.baseResponse(type: [Album].self)
            .map { response in
                return ( R.string.localizable.albums(),
                         response.map { album in
                            Data.album(.init(router: .init(owner: router.owner),
                                             data:   Album.TrackGroup(album: album,
                                                                      artistName: artist.name)))
                })
            }
            .trackView(viewIndicator: indicator)
        
        let playlists = ArtistRequest.playlists(artist: artist)
            .rx.baseResponse(type: [ArtistPlaylist].self)
            .map { response in
                return ( R.string.localizable.playlist(),
                         response.map { playlist in
                            Data.playlist(.init(router: .init(owner: router.owner),
                                                data:   playlist))
                        })
            }
            .trackView(viewIndicator: indicator)

        let records = tracksViewModel.trackViewModels
            .map { x in
                return ( R.string.localizable.songs(),
                         x.map { Data.track(trackViewModel: $0) } )
            }
        
        Observable.combineLatest([
                                  albums.asObservable(),
                                  playlists.asObservable(),
                                  records.asObservable()
            ])
            .retry(1)
            .silentCatch(handler: router.owner)
            .bind(to: data)
            .disposed(by: bag)
        
        /////progress indicator
        
        indicator.asDriver()
            .drive(onNext: { [weak h = router.owner] (loading) in
                h?.changedAnimationStatusTo(status: loading)
            })
            .disposed(by: bag)
    }
    
    let router: ArtistRouter
    fileprivate let indicator: ViewIndicator = ViewIndicator()
    fileprivate let bag = DisposeBag()
    
}

extension ArtistViewModel {
    
    func selected(item: Data) {
        
        switch item {
        case .album(let album):
            router.show(album: album.data.album)
            
        case .track(let trackViewModel):
            Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: [trackViewModel.track],
                                                                 style: .now))
            
        case .playlist(let playlist):
            router.show(playlist: playlist.data)
            
        }
        
    }
    
    func change(sourceTag: Int) {
        guard let x = Source(rawValue: sourceTag) else {
            fatalErrorInDebug("No source for tag \(sourceTag), please check your view tags")
            return
        }
        
        source.accept(x)
    }
    
}

extension ArtistViewModel {
    
    struct TracksProvider: TrackProvider {
        
        let artist: Artist
        var mode: ThumbMode { return .artwork }
        
        func provide() -> Observable<[TrackRepresentation]> {
            
            return ArtistRequest.records(artist: artist)
                .rx.response(type: BaseReponse<[Track]>.self)
                .map { $0.data.enumerated().map(TrackRepresentation.init) }
                .asObservable()
            
        }
        
    }
    
    enum Data: IdentifiableType, Equatable {
        case album(TrackGroupViewModel<Album.TrackGroup>)
        case playlist(TrackGroupViewModel<ArtistPlaylist>)
        case track(trackViewModel: TrackViewModel)
        
        var identity: String {
            switch self {
            case .album(let album):       return "album \(album.data.album.id)"
            case .playlist(let playlist): return "playlist \(playlist.data.id)"
            case .track(let t):       return "track \(t.track.id)"
            }
        }
        
        static func ==(lhs: Data, rhs: Data) -> Bool {
            switch (lhs, rhs) {
            case (.album(let x), .album(let y)):
                return x.data == y.data
                
            case (.playlist(let x), .playlist(let y)):
                return x.data == y.data
                
            case (.track(let x), .track(let y)):
                return x == y
                
            default: return false
                
            }
            
        }
        
    }
    
    enum Source: Int {
        case albums = 0
        case playlists
        case songs
    }
    
}

