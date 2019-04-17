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
    
    func provide() -> Observable<[TrackProvidable]> {
        return appState.map { $0.player.tracks }
                       .distinctUntilChanged()
                       .map { $0.orderedTracks }
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

final class NowPlayingViewModel {

    // MARK: - Private properties -

    private(set) weak var router: PlayerNowPlayingRouter!
    
    fileprivate let data = BehaviorRelay<[TrackViewModel]>(value: [])
    
    fileprivate let bag = DisposeBag()
    
    let tracksViewModel: TrackListViewModel
    
    init(router: PlayerNowPlayingRouter) {
        self.router = router
        
        
        let actions: TrackListViewModel.ActionsProvider = { _, t in
            
            guard let orderedTrack = t as? OrderedTrack else {
                return []
            }
            
            var result: [ActionViewModel] = []
            
            let user = appStateSlice.user
            
            //////1
            
            if t.track.isPlayable {
                
                let playNow = ActionViewModel(.playNow) {
                    DataLayer.get.daPlayer.switch(to: orderedTrack)
                }
                
                result.append(playNow)
                
            }
            
            //////2
            
            if user.isGuest == false {
                
                let toPlaylist = ActionViewModel(.toPlaylist) {
                    router.showAddToPlaylist(for: [t.track])
                }
                
                result.append(toPlaylist)
            }
            
            /////3
            
            let delete = ActionViewModel(.delete) {
                DataLayer.get.daPlayer.remove(track: orderedTrack)
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

}

extension NowPlayingViewModel {
    
    func selected(orderedTrack: OrderedTrack) {
        
        guard orderedTrack.track.isPlayable else {
            return
        }
        
        if appStateSlice.currentTrack != orderedTrack {
            DataLayer.get.daPlayer.switch(to: orderedTrack)
            return
        }
        
        DataLayer.get.daPlayer.flip()
    }
    
    func confirmation(for action : PlayerNowPlayingTableHeaderView.Actions) -> ConfirmationAlertViewModel.ViewModel? {

        switch action {
        case .clear:
            return ConfirmationAlertViewModel.Factory.makeClearPlaylistViewModel(actionCallback: { (actionType) in
                switch actionType {
                case .ok: DataLayer.get.daPlayer.clear()
                default: break
                }
            })
        default: return nil
        }
    }

    func perform(action : PlayerNowPlayingTableHeaderView.Actions) {
        switch action {
        case .clear:
            DataLayer.get.daPlayer.clear()
            
        default:
            break
        }
    }
    
}
