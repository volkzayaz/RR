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
        
        let playbackEndedSignal = NotificationCenter.default.rx
            .notification(NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                          object: player)
            .observeOn(MainScheduler.instance)
        
        let playbackTimeSignal = appState.map { $0.player.currentItem?.musicType }
            .notNil()
            .distinctUntilChanged()
            .asObservable()
            .flatMapLatest { [unowned p = player] (x) -> Observable<CMTime> in
                
                let duration = CMTime(seconds: 240, preferredTimescale: 1) //p.currentItem!.asset.duration
                
                return p.rx.playbackTimeFor(time: duration)
            }
            .map { CMTimeGetSeconds($0) }
        
        
        playbackEndedSignal.subscribe(onNext: { (_) in
                Dispatcher.dispatch(action: ProceedToNextItem())
            })
            .disposed(by: bag)
        
        Observable.of (playbackTimeSignal,
                       playbackEndedSignal.map { _ in 0 })
            .merge()
            .subscribe(onNext: { (x) in
                if self.isSeeking { return }
                Dispatcher.dispatch(action: Scrub(newValue: x))
            })
            .disposed(by: bag)
        
        ///scrubbing
        let x = appState
            .map { $0.player.currentItem?.state.progress ?? 0 }
        
        player.rx.status
            .map { $0 == .readyToPlay}
            .filter { $0 }
            .flatMapLatest { _ in
                return x.asObservable()
            }
            .subscribe(onNext: { [weak p = player] requestedProgress in
                
                guard let player = p,
                    let time = player.currentItem?.currentTime(),
                    !CMTIME_IS_INVALID(time),
                    abs(CMTimeGetSeconds(time) - requestedProgress) > 0.9 else {
                    return
                }
                
                self.isSeeking = true
                player.seek(to: CMTimeMakeWithSeconds(requestedProgress, preferredTimescale: Int32(NSEC_PER_SEC))) { _ in
                    self.isSeeking = false
                }
                
                //Dispatcher.dispatch(action: Play())
                
            })
            .disposed(by: bag)
        
        ///////---------
        ///////REACTING
        ///////---------
        
        appState.map { $0.player.currentItem?.state.isPlaying ?? false }
            .distinctUntilChanged()
            .drive(onNext: { [weak p = player] (isPlaying) in
                
                if isPlaying { p?.play() }
                else         { p?.pause() }
                
            })
            .disposed(by: bag)
        
        appState.map { $0.player.currentItem?.musicType }
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
    
    struct Scrub: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        state.player.currentItem?.state.progress = newValue
        return state
        }
        
        let newValue: TimeInterval
    }
    
    struct Pause: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        state.player.currentItem?.state.isPlaying = false
        return state
        }
    }
    
    struct Play: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        state.player.currentItem?.state.isPlaying = true
        return state
        }
    }
    
    struct Switch: Action { func perform(initialState: AppState) -> AppState {
        
            var state = initialState
            let flip = !(state.player.currentItem?.state.isPlaying ?? true)
            state.player.currentItem?.state.isPlaying = flip
            return state
        }
    }

    struct ChangeTrack: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        state.player.currentItem?.musicType = newValue
        return state
        }
        
        let newValue: DaPlayerState.MusicType
    }
    
}
