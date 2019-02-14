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

struct NowPlayingProvider : TrackProvider {
    
    var orderedTracks: [OrderedTrack] {
        return appStateSlice.player.tracks.orderedTracks
    }
    
    func provide() -> Observable<[Track]> {
        return appState.map { $0.player.tracks }
                       .distinctUntilChanged()
                       .map { $0.orderedTracks.map { $0.track } }
                       .asObservable()
    }
    
}

final class NowPlayingViewModel {

    // MARK: - Private properties -

    private(set) weak var router: PlayerNowPlayingRouter!
    private(set) weak var application: Application!
    
    let tracksViewModel: TrackListViewModel
    private var orderedTracks: [OrderedTrack] {
        return (tracksViewModel.trackProivder as! NowPlayingProvider).orderedTracks
    }
    
    private var errorPresenter: ErrorPresenting {
        return tracksViewModel.delegate!
    }
    
    init(router: PlayerNowPlayingRouter,
         application: Application) {
        self.router = router
        self.application = application
        
        let actions: TrackListViewModel.ActionsProvider = { list, track, indexPath in
            
            var result: [ActionViewModel] = []
            
            let maybeUser = application.user as? FanUser
            let orderedTrack = (list.trackProivder as! NowPlayingProvider).orderedTracks[indexPath.row]
            
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
        
        let select: TrackListViewModel.SelectedProvider = { list, track, indexPath in
            
            guard track.isPlayable else {
                return
            }
            
            let orderedTrack = (list.trackProivder as! NowPlayingProvider).orderedTracks[indexPath.row]
            
            precondition(orderedTrack.track == track, "Race condition appeared. Action performed with unsynced dataSource. Expected track \(track), received track \(orderedTrack.track)")
            
            if appStateSlice.currentTrack?.track != track {
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
