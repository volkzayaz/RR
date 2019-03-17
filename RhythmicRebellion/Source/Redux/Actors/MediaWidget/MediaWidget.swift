//
//  MediaWidget.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/17/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift
import MediaPlayer

struct MediaWidget {
    
    fileprivate let bag = DisposeBag()
    
    init() {
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        bindReaction()
        bindActions()
    }
    
    private func bindReaction() {

        appState.distinctUntilChanged { $0.player.currentItem == $1.player.currentItem }
            .drive(onNext: { state in
                
                //TODO: throttle progress changes as well. MPNowPLaying can increase progress value on it's own.
                //we only need to take into account considerable changes in elapsedTime
                
                ///TODO: buffer commands into windows of changes. We don't need 5 different events in a 0.5 timeframe. Instead we only interested in last state
                
                guard let currentItem = state.player.currentItem,
                      let currentTrack = state.currentTrack,
                ///TODO: investigate case: why some Track has nullable AudioFile property. Does it make sence to have track with no audioFile
                      let trackDuration = currentTrack.track.audioFile?.duration else {
                        
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
                        return
                }
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                    MPMediaItemPropertyTitle: currentTrack.track.name,
                    MPMediaItemPropertyArtist: currentTrack.track.artist.name,
                    MPMediaItemPropertyPlaybackDuration: NSNumber(value: trackDuration),
                    MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(value: currentItem.state.progress)
                ]
            })
            .disposed(by: bag)
        
    }
    
    private func bindActions() {
        
        let musicPlayer = MPRemoteCommandCenter.shared()
        
        func actionWrapper(_ action: @escaping (MPRemoteCommandEvent) -> Void) -> (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
            return { x in
                action(x)
                return .success
            }
        }
        
        func commandWrapper(_ command: MPRemoteCommand,
                            _ handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) {
            
            let disposable = command.addTarget(handler: handler)
            return Observable<Void>.never().subscribe(onDisposed: {
               command.removeTarget(disposable)
            })
            .disposed(by: self.bag)
            
        }
        
        commandWrapper(musicPlayer.playCommand, actionWrapper { _ in
            Dispatcher.dispatch(action: AudioPlayer.Play())
        })
        
        commandWrapper(musicPlayer.pauseCommand, actionWrapper { _ in
            Dispatcher.dispatch(action: AudioPlayer.Pause())
        })
        
        commandWrapper(musicPlayer.nextTrackCommand, actionWrapper { _ in
            Dispatcher.dispatch(action: ProceedToNextItem())
        })
        
        commandWrapper(musicPlayer.previousTrackCommand, actionWrapper { _ in
            Dispatcher.dispatch(action: GetBackToPreviousItem())
        })
        
    }
    
}