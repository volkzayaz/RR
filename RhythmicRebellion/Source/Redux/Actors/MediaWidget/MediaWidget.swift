//
//  MediaWidget.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/17/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import MediaPlayer
import AlamofireImage

struct MediaWidget: Actor {
    
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
                      let trackDuration = currentTrack.track.audioFile?.duration else {
                        
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
                        return
                }
                
                let x = MPNowPlayingInfoCenter.default()
                
                x.nowPlayingInfo?[MPMediaItemPropertyTitle] = state.currendPlayableTitle
                x.nowPlayingInfo?[MPMediaItemPropertyArtist] = currentTrack.track.artist.name
                x.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: trackDuration)
                x.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: currentItem.state.progress)
                
            })
            .disposed(by: bag)
        
        appState.distinctUntilChanged { $0.currentTrack == $1.currentTrack }
            .map { $0.currentTrack?.track.images.first?.simpleURL ?? "" }
            .flatMapLatest { ImageRetreiver.imageForURLWithoutProgress(url: $0) }
            .drive(onNext: { (maybeImage) in
                
                var artwork: MPMediaItemArtwork? = nil
                if let i = maybeImage {
                    
                    let m = min(i.size.width, i.size.height)
                    let size = CGSize(width: m, height: m)
                    
                    artwork = MPMediaItemArtwork(boundsSize: size) { size in
                        return AspectScaledToFillSizeFilter(size: size).filter(i)
                    }
                }
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
                
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
        
        
        appState.map { $0.canForward }
            .distinctUntilChanged()
            .drive(musicPlayer.nextTrackCommand.rx.isEnabled)
            .disposed(by: bag)
        
        appState.map { $0.canBackward }
            .distinctUntilChanged()
            .drive(musicPlayer.previousTrackCommand.rx.isEnabled)
            .disposed(by: bag)
        
    }
    
}

extension Reactive where Base: MPRemoteCommand {
    
    /// Bindable sink for `enabled` property.
    public var isEnabled: Binder<Bool> {
        return Binder(self.base) { command, value in
            command.isEnabled = value
        }
    }
}
