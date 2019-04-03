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
    private(set) weak var application: Application!
    
    fileprivate let data = BehaviorRelay<[TrackViewModel]>(value: [])
    fileprivate let trackObserver: TrackListViewModel.Observer
    
    fileprivate let bag = DisposeBag()
    
    let tracksViewModel: TrackListViewModel
    
    private var errorPresenter: ErrorPresenting {
        return tracksViewModel.delegate!
    }
    
    init(router: PlayerNowPlayingRouter,
         application: Application) {
        self.router = router
        self.application = application
        
        let actions: TrackListViewModel.ActionsProvider = { list, t, _ in
            
            guard let orderedTrack = t as? OrderedTrack else {
                return []
            }
            
            var result: [ActionViewModel] = []
            
            let user = appStateSlice.user
            
            //////1
            
            if user.isGuest == false {
                
                let toPlaylist = ActionViewModel(.toPlaylist) {
                    router.showAddToPlaylist(for: [t.track])
                }
                
                result.append(toPlaylist)
            }
            
            //////2
            
            if t.track.isPlayable {
                
                let playNow = ActionViewModel(.playNow) {
                    list.play(orderedTrack: orderedTrack)
                }
                
                result.append(playNow)
                
            }
            
            /////3
            
            let delete = ActionViewModel(.delete) {
                list.remove(orderedTrack: orderedTrack)
            }
            
            result.append(delete)
            
            return result
            
        }
        
        let select: TrackListViewModel.SelectedProvider = { list, t, _ in
            
            guard let orderedTrack = t as? OrderedTrack else {
                return
            }
            
            guard orderedTrack.track.isPlayable else {
                return
            }
            
            if appStateSlice.currentTrack != orderedTrack {
                list.play(orderedTrack: orderedTrack)
                return
            }

            DataLayer.get.daPlayer.flip()
            
        }
        
        tracksViewModel = TrackListViewModel(application: application,
                                             dataProvider: NowPlayingProvider(),
                                             router: TrackListRouter(owner: router.owner),
                                             actionsProvider: actions,
                                             selectedProvider: select)
        
        trackObserver = TrackListViewModel.Observer(list: tracksViewModel,
                                                    handler: router.owner)
        
        trackObserver.trackViewModels
            .bind(to: data)
            .disposed(by: bag)
        
    }

}

extension NowPlayingViewModel {
    
    func load(with delegate: TrackListBindings) {
        tracksViewModel.load(with: delegate)
    }

}


extension NowPlayingViewModel {
    
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
