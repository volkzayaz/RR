//
//  AVPlayer+rx.swift
//  SmartReading
//
//  Created by Vlad Soroka on 9/10/17.
//  Copyright © 2017 All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

import AVFoundation

extension Reactive where Base == AVPlayer {
    
    func playbackTimeFor(time: CMTime) -> Observable<CMTime> {
        
        return Observable.create { (subscriber) -> Disposable in
            
            let duration = CMTimeGetSeconds(time)
            
            guard duration > 0 else {
                subscriber.onNext(CMTime.zero)
                return Disposables.create()
            }
            
            /*
             * timescale use for pereodic update
             */
            
            var interval = duration / 75;
            
            if interval > 1 {
                interval = 0.99
            }
            
            let observer = self.base.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1,
                                                                                 preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                                                        queue: DispatchQueue.main) { (x) in
                subscriber.onNext(x)
            }
            
            return Disposables.create {
                self.base.removeTimeObserver(observer)
            }
            
        }
        
    }
    
    var rate: Observable<Float> {
        return base.rx.observe(Float.self, "rate")
                    .startWith(base.rate)
                    .notNil()
    }
    
    var status: Observable<AVPlayer.Status> {
        
        ///will probably need to manually unwrap NSNumber to AVPlayerStatus
        return base.rx.observeWeakly(AVPlayer.Status.self, "status")
            .startWith(base.status)
            .notNil()
    }
    
    var error: Observable<Error?> {
        return base.rx.observeWeakly(NSError.self, "error")
            .map { $0 as Error? }
    }
}

extension AVPlayer {
    var rx: Reactive<AVPlayer> {
        return Reactive(self)
    }
}
