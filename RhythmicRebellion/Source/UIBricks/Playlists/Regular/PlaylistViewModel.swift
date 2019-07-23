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
    
    private let router: PlaylistRouter
    
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
        
        headerViewModel = PlaylistHeaderViewModel(playlist: provider.playlist)
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
            RRSheet.Action(option: .playNow, action: {
                Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: tracks,
                                                                     style: .now))
            }),
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
        ]
        
        if appStateSlice.user.isGuest == false,
           let p = tracksViewModel.trackProivder as? AttachableProvider {

            let toPlaylist = RRSheet.Action(option: .addToLibrary) {
                self.router.showAddToPlaylist(for: p)
            }
            
            actions.append(toPlaylist)
        }
        
        let provider = (tracksViewModel.trackProivder as! PlaylistProvider)
        
        if let x = provider as? DeletablePlaylistProvider, x.canDelete {
            
            actions.append(RRSheet.Action(option: .delete) { [unowned self, weak o = router.owner] in
                let _ = x.drop()
                    .silentCatch(handler: self.router.owner)
                    .subscribe(onNext: {
                        o?.navigationController?.popViewController(animated: true)
                    })
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
