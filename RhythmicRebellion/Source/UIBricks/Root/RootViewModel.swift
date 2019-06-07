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
