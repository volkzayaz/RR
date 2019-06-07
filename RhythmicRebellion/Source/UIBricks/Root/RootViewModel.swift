//
//  RootViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/23/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension RootViewModel {
    
    var progressFraction: Driver<CGFloat> {
        
        return appState
            .distinctUntilChanged { $0.player.currentItem == $1.player.currentItem }
            .map { newState in
                
                guard let totalTime = newState.currentTrack?.track.audioFile?.duration,
                    let currentTime = newState.player.currentItem?.state.progress else {
                        return 0
                }
                
                return CGFloat(currentTime / TimeInterval(totalTime))
        }
        .map { $0 == 0 ? 0.01 : $0 }
        
    }
    
    var title: Driver<String> {
        
        return appState
            .distinctUntilChanged { $0.activePlayable == $1.activePlayable }
            .map { $0.currendPlayableTitle }
        
    }
    
    var artist: Driver<String> {
        
        return appState
            .distinctUntilChanged { $0.currentTrack == $1.currentTrack }
            .map { $0.currentTrack?.track.artist.name ?? "" }
        
    }
    
    var isArtistFollowed: Driver<Bool> {
        
        return appState.map { newState in
            
            guard let artist = newState.currentTrack?.track.artist else { return false }
            
            return newState.user.isFollower(for: artist.id)
        }
    }
    
    var attributes: Driver<[TrackViewModel.Attribute]> {
        
        return appState.distinctUntilChanged { $0.currentTrack == $1.currentTrack &&
                                               $0.player.tracks.previewTime == $1.player.tracks.previewTime }
            .map { state in
                
                guard let track = state.currentTrack?.track else {
                    return []
                }
                
                let user = state.user
                var x: [TrackViewModel.Attribute] = []
                
                if track.isCensorship {
                    x.append(.explicitMaterial)
                }
                
                if user.hasPurchase(for: track) ||
                    (user.isFollower(for: track.artist.id) && track.isFollowAllowFreeDownload) {
                    x.append(.downloadEnabled)
                }
                
                if case .limit45? = track.previewType {
                    x.append( .raw(" 45 SEC ") )
                    return x
                }
                else if case .limit45? = track.previewType {
                    x.append( .raw(" 90 SEC ") )
                    return x
                }
                else if case .full? = track.previewType {
                    
                    let z = TrackPreviewOptionViewModel(type: .init(with: track,
                                                                    user: user,
                                                                    μSecondsPlayed: state.player.tracks.previewTime[track.id]))
                    
                    if case .fullLimitTimes(let previewTimes) = z.type {
                        x.append(.raw("   X\(previewTimes)   "))
                    }
                    
                    return x
                }
                
                return x
                
        }
    }
    
}

struct RootViewModel : MVVM_ViewModel {
    
    /** Reference dependent viewModels, managers, stores, tracking variables...
     
     fileprivate let privateDependency = Dependency()
     
     fileprivate let privateTextVar = BehaviourRelay<String?>(nil)
     
     */
    
    init(router: RootRouter) {
        self.router = router
        
        /**
         
         Proceed with initialization here
         
         */
        
        /////progress indicator
        
        indicator.asDriver()
            .drive(onNext: { [weak h = router.owner] (loading) in
                h?.changedAnimationStatusTo(status: loading)
            })
            .disposed(by: bag)
    }
    
    let router: RootRouter
    fileprivate let indicator: ViewIndicator = ViewIndicator()
    fileprivate let bag = DisposeBag()
    
}

extension RootViewModel {
    
    func presentVideo() {
        router.presentVideo()
    }
    
    func presentLyrics() {
        router.presentLyrics()
    }
    
    func presentPromo() {
        router.presentPromo()
    }
    
    func presentPlaying() {
        router.presentPlaying()
    }
    
    func presentPlayer() {
        router.presentPlayer()
    }
    
}
