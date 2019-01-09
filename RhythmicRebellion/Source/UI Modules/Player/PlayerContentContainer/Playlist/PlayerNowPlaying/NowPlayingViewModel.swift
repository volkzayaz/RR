//
//  PlayerNowPlayingControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

struct NowPlayingProvider : TrackProvider {
    
    let player: Player
    
    var playlistItems: [PlayerPlaylistItem] {
        return player.playlistItems
    }
    
    func provide(completion: (Box<[Track]>) -> Void) {
        return completion( .value( val: playlistItems.map { $0.track } ) )
    }
    
}

final class NowPlayingViewModel {

    // MARK: - Private properties -

    private(set) weak var router: PlayerNowPlayingRouter!
    private(set) weak var application: Application!
    private(set) weak var player: Player!
    
    let tracksViewModel: TrackListViewModel
    private var playlistItems: [PlayerPlaylistItem] {
        return (tracksViewModel.trackProivder as! NowPlayingProvider).playlistItems
    }
    
    private var errorPresenter: ErrorPresenting {
        return tracksViewModel.delegate!
    }
    
    init(router: PlayerNowPlayingRouter,
         application: Application,
         player: Player,
         audioFileLocalStorageService: AudioFileLocalStorageService) {
        self.router = router
        self.application = application
        self.player = player
        
        let actions: TrackListViewModel.ActionsProvider = { list, track, indexPath in
            
            var result: [ActionViewModel] = []
            
            let maybeUser = application.user as? FanUser
            let playlistItem = (list.trackProivder as! NowPlayingProvider).playlistItems[indexPath.row]
            
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
                    list.play(playlistItem: playlistItem)
                }
                
                result.append(playNow)
                
            }
            
            /////3
            
            let delete = ActionViewModel(.delete) {
                list.delete(playlistItem: playlistItem)
            }
            
            result.append(delete)
            
            return result
            
        }
        
        let select: TrackListViewModel.SelectedProvider = { list, track, indexPath in
            
            guard track.isPlayable else {
                return
            }
            
            let playlistItem = (list.trackProivder as! NowPlayingProvider).playlistItems[indexPath.row]
            
            precondition(playlistItem.track == track, "Race condition appeared. Action performed with unsynced dataSource. Expected track \(track), received track \(playlistItem.track)")
            
            
            ///This piece of logic is still a mystery for me.
            ///Specifically, why is it different from same conditon present in PlaylistViewModel
            let condition = !(player.currentItem?.playlistItem.track == track)
            
            if condition {
                list.play(playlistItem: playlistItem)
                return
            }
            
            player.flipPlayState()
            
        }
        
        tracksViewModel = TrackListViewModel(application: application,
                                             player: player,
                                             dataProvider: NowPlayingProvider(player: player),
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
            return ConfirmationAlertViewModel.Factory.makeClearPlaylistViewModel(actionCallback: { [weak self] (actionType) in
                switch actionType {
                case .ok: self?.player?.clearPlaylist()
                default: break
                }
            })
        default: return nil
        }
    }

    func perform(action : PlayerNowPlayingTableHeaderView.Actions) {
        switch action {
        case .clear:
            self.player?.clearPlaylist()
        default:
            break
        }
    }
    
}
