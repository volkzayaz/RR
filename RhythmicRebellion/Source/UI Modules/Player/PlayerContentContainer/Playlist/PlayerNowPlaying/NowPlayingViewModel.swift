//
//  PlayerNowPlayingControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class NowPlayingViewModel {

    // MARK: - Private properties -

    private(set) weak var router: PlayerNowPlayingRouter!
    private(set) weak var application: Application!
    private(set) weak var player: Player!
    private(set) weak var audioFileStorage: AudioFileLocalStorageService!
    
    private var playlistItems: [PlayerPlaylistItem] = []

    lazy var tracksViewModel = TrackListViewModel(router: router,
                                                  application: application,
                                                  player: player,
                                                  audioFileLocalStorageService: audioFileStorage,
                                                  provider: self)

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
        self.audioFileStorage = audioFileLocalStorageService
    }

}

extension NowPlayingViewModel: TrackProvider {
    
    func provide(completion: (Box<[Track]>) -> Void) {
        
        let items = player?.playlistItems ?? []
        playlistItems = items
        
        return completion( .value( val: items.map { $0.track } ) )
    }
    
    func actions(for track: Track, indexPath: IndexPath) -> [ActionViewModel] {
        
        guard let user = application?.user as? FanUser else {
            return []
        }
        
        let item = playlistItems[indexPath.row]
        
        let ftp = ActionViewModel(.forceToPlay) { [weak self] in
            
            self?.application?
                .allowPlayTrackWithExplicitMaterial(trackId: track.id,
                                                    completion: { res in
                                                        if case .failure(let error) = res {
                                                            self?.errorPresenter.show(error: error)
                                                        }
                                                    })
        }
        
        let dnp = ActionViewModel(.doNotPlay) { [weak self] in
            
            self?.application?
                .disallowPlayTrackWithExplicitMaterial(trackId: track.id,
                                                       completion: { res in
                                                        if case .failure(let error) = res {
                                                            self?.errorPresenter.show(error: error)
                                                        }
                })
        }
    
        let pn = ActionViewModel(.playNow) { [weak self] in
            
            self?.player?.performAction(.playNow,
                                       for: item,
                                       completion: { [weak self] (error) in
                                        guard let error = error else { return }
                                        self?.errorPresenter.show(error: error)
                })
            
        }

        let delete = ActionViewModel(.delete) { [weak self] in
            
            self?.player?.performAction(.delete,
                                        for: item,
                                        completion: { [weak self] (error) in
                                        guard let error = error else { return }
                                        self?.errorPresenter.show(error: error)
            })
            
        }
        
        let toPlaylist = ActionViewModel(.toPlaylist) { [weak self] in
            self?.router?.showAddToPlaylist(for: [track])
        }
        
        var result: [ActionViewModel] = []
        
        if user.isCensorshipTrack(track) &&
          !user.profile.forceToPlay.contains(track.id) {
            result.append(ftp)
        }
            
        if user.isCensorshipTrack(track) &&
           user.profile.forceToPlay.contains(track.id) {
            result.append(dnp)
        }
        
        if track.isPlayable {
            result.append(pn)
        }
        
        if application?.user?.isGuest == false {
            result.append(toPlaylist)
        }
        
        result.append(delete)
        
        if user.hasPurchase(for: track) {
            ///No proper action is available so far
            //result.append(add)
        }
        
        return result
    }
    
    var selected: (Track, IndexPath) -> Void {
        
        return { [weak self] (track, indexPath) in
            
            guard track.isPlayable else {
                return
            }
            
            guard let playlistItem = self?.playlistItems[indexPath.row] else {
                fatalError("Select action perfromed for not existing playlist item. Expected track \(track)")
            }
            
            precondition(playlistItem.track == track, "Race condition appeared. Action performed with unsynced dataSource. Expected track \(track), received track \(playlistItem.track)")
            
            
            ///This piece of logic is still a mystery for me.
            ///Specifically, why is it different from same conditon present in PlaylistContentControllerViewModel
            let condition = !(self?.player?.currentItem?.playlistItem.track == track)
            
            if condition {
                
                self?.player?.performAction(.playNow,
                                            for: playlistItem,
                                            completion: { [weak self] (error) in
                                                guard let error = error else { return }
                                                self?.errorPresenter.show(error: error)
                })
                return
            }
            
            self?.player?.flipPlayState()
            
        }
        
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
