//
//  AudioPlayer.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 2/8/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

import AVFoundation
import MediaPlayer

extension AudioPlayer {

    var currentProgress: Driver<TimeInterval> {
        return appState.map { $0.player.currentItem?.state.progress ?? 0 }
    }
    
    var leftProgressString: Driver<String> {
        return appState.map { $0.player.currentItem?.state.progress.audioDurationString ?? "" }
    }
    
    var rightProgressString: Driver<String> {
        
        let isReady = player.rx.status
                        .map { $0 == .readyToPlay}
        
        return Driver
            .combineLatest(isReady.asDriver(onErrorJustReturn: false),
                           currentProgress) { ($0, $1) }
            .filter { $0.0 }
            .map { [weak p = player] tuple in
                
                guard let a = p?.currentItem else {
                    return ""
                }
                
                let progressValue = tuple.1
                let duration = CMTimeGetSeconds(a.duration)
                let remain = duration - progressValue
                
                return "\(remain.audioDurationString)"
            }
        
    }
    
    var isPlaying: Driver<Bool> {
        return appState.map { $0.player.currentItem?.state.isPlaying ?? false }
                .distinctUntilChanged()
    }
    
}

class AudioPlayer: NSObject {
    
    fileprivate let player: AVQueuePlayer = AVQueuePlayer(items: [])
    
    fileprivate var isSeeking = false
    
    override init() {
        
        super.init()
        
        ///////---------
        ///////Dispatching
        ///////---------
        
        NotificationCenter.default.rx
            .notification(.AVPlayerItemDidPlayToEndTime,
                          object: nil)
            .subscribe(onNext: { (_) in
                Dispatcher.dispatch(action: ProceedToNextItem())
            })
            .disposed(by: bag)
        
        
        appState.map { $0.activePlayable }
            .notNil()
            .distinctUntilChanged()
            .asObservable()
            .flatMapLatest { [unowned p = player] (x) -> Observable<CMTime> in
                
                let duration = CMTime(seconds: 240, preferredTimescale: 1) //p.currentItem!.asset.duration
                
                return p.rx.playbackTimeFor(time: duration)
                    .skip(1)///sends out initial 0 upon audio being ready to play.
                            ///we are not interested in that event
            }
            .map { CMTimeGetSeconds($0) }
            .subscribe(onNext: { [unowned self] (x) in
            
                ////This is a bad implementation of the event:
                ////Whenever local audioPlayer played back some portion of audio
                ///Unfortunatelly periodicTimeObserver fires even if player is not playing
                ///if player seeked for new value
                ///if player starts or pauses playback
                ////therefore we manually filter out some of these events
                if self.isSeeking { return }
                
                Dispatcher.dispatch(action: OrganicScrub(newValue: x))
            })
            .disposed(by: bag)
        
        ///////---------
        ///////REACTING
        ///////---------
        
        
        let x = appState
            .map { $0.player.currentItem?.state }
        
        player.rx.status
            .map { $0 == .readyToPlay}
            .filter { $0 }
            .flatMapLatest { _ in
                return x.asObservable()
            }
            .subscribe(onNext: { [weak p = player] state in
                
                let requestedProgress = state?.progress ?? 0
                
                guard let player = p,
                    let time = player.currentItem?.currentTime(),
                    !CMTIME_IS_INVALID(time),
                    state?.skipSeek == nil else {
                    return
                }
                
                self.isSeeking = true
                player.seek(to: CMTimeMakeWithSeconds(requestedProgress, preferredTimescale: Int32(NSEC_PER_SEC))) { _ in
                    self.isSeeking = false
                }
                
            })
            .disposed(by: bag)
        
        appState.map { $0.player.currentItem?.state }
            .notNil()
            .distinctUntilChanged()
            .drive(onNext: { [weak p = player] (state) in
                
                ///we will not play actual playback item if it wasn't initiated by our client
                if state.isPlaying && state.isOwn { p?.play() }
                else                              { p?.pause() }
                
            })
            .disposed(by: bag)
        
        appState.map { $0.activePlayable }
            .distinctUntilChanged()
            .notNil()
            .drive(onNext: { [weak p = player] (item) in
                
                let url: URL
                switch item {
                case .addon(let x): url = URL(string: x.audioFile.urlString)!
                case .track(let x): url = URL(string: x.audioFile!.urlString)!
                }
                
                if let x = p?.currentItem?.asset as? AVURLAsset,
                    x.url == url {
                    return;
                }
                
                p?.removeAllItems()
                p?.insert(AVPlayerItem(url: url),
                          after: nil)
                
            })
            .disposed(by: rx.disposeBag)
        
    }
    
    fileprivate let bag = DisposeBag()
    
}

extension AudioPlayer {

    ///TODO: prepare proper naming and documentation on OrganicScrub and skipSeek stuff
    private struct OrganicScrub: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        
        guard let currentTrackState = state.player.currentItem?.state else {
            return state
        }
        
        state.player.currentItem?.state = .init(progress: newValue,
                                                isPlaying: currentTrackState.isPlaying,
                                                skipSeek: ())
        return state
        }
        
        let newValue: TimeInterval
    }
    
    struct Scrub: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        
        guard let currentTrackState = state.player.currentItem?.state else {
            return state
        }
        
        state.player.currentItem?.state = .init(progress: newValue,
                                                isPlaying: currentTrackState.isPlaying)
        return state
        }
        
        let newValue: TimeInterval
    }
    
    struct Pause: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        
        guard let currentTrackState = state.player.currentItem?.state else {
            return state
        }
        
        state.player.currentItem?.state = .init(progress: currentTrackState.progress,
                                                isPlaying: false)
        return state
        }
    }
    
    struct Play: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        
        guard let currentTrackState = state.player.currentItem?.state else {
            return state
        }
        
        state.player.currentItem?.state = .init(progress: currentTrackState.progress,
                                                isPlaying: true)
        return state
        }
    }
    
    struct Switch: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        
        guard let currentTrackState = state.player.currentItem?.state else {
            return state
        }
        
        state.player.currentItem?.state = .init(progress: currentTrackState.progress,
                                                isPlaying: !currentTrackState.isPlaying)
        return state
        }
    }
    
}
