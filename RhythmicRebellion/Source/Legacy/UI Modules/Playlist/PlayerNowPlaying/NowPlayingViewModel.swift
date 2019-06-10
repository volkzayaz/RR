//
//  PlayerNowPlayingControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

struct NowPlayingProvider : TrackProvider {
    
    var mode: TrackViewModel.ThumbMode { return .artwork }
    
    func provide() -> Observable<[TrackRepresentation]> {
        return appState.map { $0.player.tracks }
                       .distinctUntilChanged()
                       .map { $0.orderedTracks.map(TrackRepresentation.init) }
                       .asObservable()
    }
    
}

extension NowPlayingViewModel {
    
    var dataSource: Driver<[AnimatableSectionModel<String, TrackViewModel>]> {
        return data.asDriver().map { x in
            return [AnimatableSectionModel(model: "", items: x)]
        }
    }
    
}

struct NowPlayingViewModel {

    fileprivate let data = BehaviorRelay<[TrackViewModel]>(value: [])
    
    let tracksViewModel: TrackListViewModel
    
    init(router: NowPlayingRouter) {
        self.router = router
        
        
        let actions: TrackListViewModel.ActionsProvider = { _, t in
            
            guard let orderedTrack = t as? OrderedTrack else {
                return []
            }
            
            var result: [ActionViewModel] = []
            
            if t.track.isPlayable {
                
                let playNow = ActionViewModel(.playNow) {
                    Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: orderedTrack,
                                                                shouldPlayImmidiatelly: true))
                }
                
                result.append(playNow)
                
            }
            
            //////2
            
            if appStateSlice.user.isGuest == false {
                
                let toPlaylist = ActionViewModel(.toPlaylist) {
                    router.showAddToPlaylist(for: [t.track])
                }
                
                result.append(toPlaylist)
            }
            
            /////3
            
            let delete = ActionViewModel(.delete) {
                Dispatcher.dispatch(action: RemoveTrack(orderedTrack: orderedTrack))
            }
            
            result.append(delete)
            
            return result
            
        }
        
        tracksViewModel = TrackListViewModel(dataProvider: NowPlayingProvider(),
                                             router: TrackListRouter(owner: router.owner),
                                             actionsProvider: actions)
        
        tracksViewModel.trackViewModels
            .drive(data)
            .disposed(by: bag)
        
    }

    private let router: NowPlayingRouter
    fileprivate let bag = DisposeBag()
    
}

extension NowPlayingViewModel {
    
    func selected(orderedTrack: OrderedTrack) {
        
        guard orderedTrack.track.isPlayable else {
            return
        }
        
        if appStateSlice.currentTrack != orderedTrack {
            Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: orderedTrack,
                                                        shouldPlayImmidiatelly: true))
            return
        }
        
        Dispatcher.dispatch(action: AudioPlayer.Switch())
    }

}