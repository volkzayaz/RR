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

class AudioPlayer: NSObject, Actor {
    
    fileprivate let player: AVPlayer = AVPlayer()
    
    fileprivate var isSeeking = false
    
    override init() {
        
        super.init()
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        
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
                if self.player.rate == 0 { return }
                
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
        
        appState
            .distinctUntilChanged { $0.player.currentItem?.state == $1.player.currentItem?.state }
            .drive(onNext: { [weak p = player] (state) in
            
                guard let s = state.player.currentItem?.state,
                    s.isPlaying,
                    state.player.lastChangeSignatureHash.isOwn else {
                    
                    p?.pause()
                        
                    return
                }
                
                ////subscequent calls to |play| make AVAudioSession.interruptionNotification act weird
                ////and sometimes make it not deliver .ended notification
                if p?.rate == 0 {
                    p?.play()
                }
                
            })
            .disposed(by: bag)
        
        appState
            .distinctUntilChanged { $0.activePlayable == $1.activePlayable &&
                                    $0.currentTrack == $1.currentTrack }
            .map { $0.activePlayable }
            .notNil()
            .drive(onNext: { [weak p = player] (item) in
                
                let url: URL
                switch item {
                case .addon(let x):         url = URL(string: x.audioFile.urlString)!
                case .track(let x):         url = URL(string: x.audioFile!.urlString)!
                case .minusOneTrack(let x): url = URL(string: x.backingAudioFile!.urlString)!
                case .stub(let x, _):       url = URL(string: x.urlString)!
                }
                
                if let x = p?.currentItem?.asset as? AVURLAsset,
                    x.url == url {
                    return;
                }
              
                let i = AVPlayerItem(url: url)
                
                p?.replaceCurrentItem(with: i)
                
            })
            .disposed(by: rx.disposeBag)
        
        ///////---------
        ///////Buffering and loading state
        ///////---------
        
        ////TODO:
        ///1. Add loading indicator for all times when we do not play media, but waiting for it
        ///2. Add buffering progress UI (when media chunk has been loaded and is ready to be played back)
        ///3. Handle cases when seek(for:) results in player bugs (continues old playback, does not dispatch |next| events via |reasonForWaitingToPlay|)
        
        player.rx.reasonForWaitingToPlay
            .subscribe(onNext: { (x) in
                print("New waiting resolve \(x)")
            })
            .disposed(by: bag)
        
        player.rx.timeControlStatus
            .subscribe(onNext: { (x) in
                print("New timecontrol status \(x)")
            })
            .disposed(by: bag)
        
        
        ///////---------
        ///////Audio Session juggling
        ///////---------
        
        
        ////1. AudioSession interruption (calls, notifications...)
        let _ =
        NotificationCenter.default
            .addObserver(forName: AVAudioSession.interruptionNotification,
                         object: AVAudioSession.sharedInstance(),
                         queue: nil) { notification in
                            
                            guard let userInfo = notification.userInfo,
                                let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                                let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
                            
                            if type == .began {
                                
                                Dispatcher.dispatch(action: Pause())
                                
                                return
                            }
                            
                            if type == .ended,
                               let raw = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                               AVAudioSession.InterruptionOptions(rawValue: raw).contains(.shouldResume) {
                                
                                Dispatcher.dispatch(action: Play())
                                
                            }
        }
        

        ////2. Headphones unplug
        let _ =
        NotificationCenter.default
            .addObserver(forName: AVAudioSession.routeChangeNotification,
                         object: AVAudioSession.sharedInstance(),
                         queue: nil) { notification in
               
                            guard let rawValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                                  let changeReason = AVAudioSession.RouteChangeReason(rawValue: rawValue) else { return }
                            
                            switch changeReason {
                                
                            case .oldDeviceUnavailable:
                                
                                if let previousRoute = notification.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription,
                                    previousRoute.outputs.contains(where: { $0.portType == .headphones }) {
                                    
                                    Dispatcher.dispatch(action: Pause())
                                    
                                }
                                
                            default: return
                                
                            }

        }
        
    }
    
    fileprivate let bag = DisposeBag()
    
}
