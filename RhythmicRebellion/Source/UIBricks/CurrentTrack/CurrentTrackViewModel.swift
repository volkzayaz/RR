//
//  CurrentTrackViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/5/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension CurrentTrackViewModel {

    var rightProgress: Driver<String> {
        return appState.distinctUntilChanged { $0.player.currentItem?.activeTrackHash == $1.player.currentItem?.activeTrackHash }
            .map { newState in
                guard let duration = newState.currentTrack?.track.audioFile?.duration else {
                    return "--:--"
                }
                
                return TimeInterval(duration).stringFormatted()
        }
    }
    
    var leftProgress: Driver<String> {
        
        return appState
            .map { $0.player.currentItem?.state }
            .notNil()
            .distinctUntilChanged()
            .map { $0.progress.stringFormatted() }
        
    }
    
    var progressFraction: Driver<Float> {
        
        return appState
            .distinctUntilChanged { $0.player.currentItem == $1.player.currentItem }
            .map { newState in
                
                guard let totalTime = newState.currentTrack?.track.audioFile?.duration,
                    let currentTime = newState.player.currentItem?.state.progress else {
                        return 0
                }
                
                return Float(currentTime / TimeInterval(totalTime))
        }
        
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
    
    var imageURL: Driver<String> {
        return appState.map { $0.currentTrack?.track.images.first?.simpleURL ?? "" }
            .distinctUntilChanged()
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
    
    ///binary state
    
    var isPlaying: Driver<Bool> {
        return appState.map { $0.player.currentItem?.state.isPlaying }
            .notNil()
            .distinctUntilChanged()
    }
    
    var isArtistFollowed: Driver<Bool> {
        
        return appState.map { newState in
            
            guard let artist = newState.currentTrack?.track.artist else { return false }
            
            return newState.user.isFollower(for: artist.id)
        }
    }
    
    var isBlocked: Driver<Bool> {
        return appState.distinctUntilChanged({ (lhs, rhs) -> Bool in
            return lhs.player.isBlocked == rhs.player.isBlocked
        })
            .map { state in
                
                if state.player.lastChangeSignatureHash.isOwn {
                    return false
                }
                
                return state.player.isBlocked
            }
            .distinctUntilChanged()
    }
    
    var likeState: Driver<Track.LikeStates> {
        return appState
            .map { newState in
                
                guard let currentTrack = newState.currentTrack else { return .none }
                
                return newState.user.likeState(for: currentTrack.track)
        }
    }
    
    //// Bool restrictions
    
    var canSeek: Driver<Bool> {
        return appState.distinctUntilChanged { $0.player.currentItem == $1.player.currentItem }
            .map { $0.canSeek }
    }
    
    var canFollow: Driver<Bool> {
        return appState.map { $0.currentTrack != nil }
    }
    
    var canTogglePlay: Driver<Bool> {
        return appState.map { $0.activePlayable != nil }
    }
    
    var canForward: Driver<Bool> {
        return appState.distinctUntilChanged { $0.player.currentItem == $1.player.currentItem }
            .map { $0.canForward }
    }
    var canBackward: Driver<Bool> {
        return appState.distinctUntilChanged { $0.player.currentItem == $1.player.currentItem }
            .map { $0.canBackward }
    }
    
    var nextUpString: Driver<String> {
        return appState
            .distinctUntilChanged { $0.currentTrack == $1.currentTrack }
            .map { $0.nextTrack?.track.name ?? "" }
    }
    
    var sliderColor: Driver<UIColor> {
        return appState.map { $0.player.isBlocked }
            .distinctUntilChanged()
            .map { $0 ? UIColor.blockedYellow : UIColor.primaryPink }
    }
    
    var sliderThumb: Driver<UIImage> {
        
        let thumb = R.image.thumb()!
        let rect = CGRect(x: 0, y: 0, width: thumb.size.width, height: thumb.size.height)
        UIGraphicsBeginImageContextWithOptions(thumb.size, false, 0)
        UIColor.clear.setFill()
        UIRectFill(rect)
        guard let blankImg = UIGraphicsGetImageFromCurrentImageContext() else { fatalError() }
        
        UIGraphicsEndImageContext()
        
        return appState.map { $0.player.isBlocked }
            .distinctUntilChanged()
            .map { $0 ? blankImg : thumb }
    }
    
}

struct CurrentTrackViewModel : MVVM_ViewModel {
    
    /** Reference dependent viewModels, managers, stores, tracking variables...
     
     fileprivate let privateDependency = Dependency()
     
     fileprivate let privateTextVar = BehaviourRelay<String?>(nil)
     
     */
    
    init(router: CurrentTrackRouter) {
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
    
    let router: CurrentTrackRouter
    fileprivate let indicator: ViewIndicator = ViewIndicator()
    fileprivate let bag = DisposeBag()
    
}

extension CurrentTrackViewModel {
    
    func togglePlay() {
        Dispatcher.dispatch(action: AudioPlayer.Switch())
    }
    
    func forward() {
        Dispatcher.dispatch(action: ProceedToNextItem())
    }
    
    func backward() {
        Dispatcher.dispatch(action: GetBackToPreviousItem())
    }
    
    func like() {
        guard let track = appStateSlice.currentTrack?.track else { return }
        guard !appStateSlice.user.isGuest else {
            
            ////TODO: kill it with fire!!
            router.owner.dismissController()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "navigateToSignIn"), object: nil)
            
            return
        }
        
        let newState: Track.LikeStates = appStateSlice.user.likeState(for: track) == .liked ? .none : .liked
        
        UserManager.update(track: track, likeState: newState).subscribe()
        
    }
    
    func dislike() {
        guard let track = appStateSlice.currentTrack?.track else { return }
        guard !appStateSlice.user.isGuest else {
            
            ////TODO: kill it with fire!!
            router.owner.dismissController()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "navigateToSignIn"), object: nil)
            
            return
        }
        
        let newState: Track.LikeStates = appStateSlice.user.likeState(for: track) == .disliked ? .none : .disliked
        
        UserManager.update(track: track, likeState: newState).subscribe()
    }
    
    func scrub(to progress: Float) {
        Dispatcher.dispatch(action: ScrubToFraction(fraction: progress))
    }
    
    func follow() {
        
        guard let track = appStateSlice.currentTrack?.track else { return }
        guard !appStateSlice.user.isGuest else {
            
            ////TODO: kill it with fire!!
            router.owner.dismissController()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "navigateToSignIn"), object: nil)
            
            return
        }
        
        UserManager.follow(shouldFollow: !appStateSlice.user.isFollower(for: track.artist.id),
                           artistId: track.artist.id)
            .subscribe()
    }
    
    func moreOptions() {
        //Download, Add to Library, Share, Delete from Playing options are displayed.
        
        guard let x = appStateSlice.currentTrack else { return }
        let r = router
        
        var result: [RRSheet.Action] = []
        
        if appStateSlice.user.isGuest == false {
            result.append( .init(option: .addToLibrary) {
                r.showAddToPlaylist(for: x.track)
            })
        }
        
        result.append( .init(option: .delete) {
            Dispatcher.dispatch(action: RemoveTrack(orderedTrack: x))
        })
        
        router.owner.show(viewModels: result)
    }

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
    
}


class RRSlider : UISlider {
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var newBounds = super.trackRect(forBounds: bounds)
        newBounds.size.height = 3
        return newBounds
    }
    
}
