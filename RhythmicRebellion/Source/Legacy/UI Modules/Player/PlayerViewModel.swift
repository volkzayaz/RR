//
//  PlayerControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import CoreMedia
import UIKit
import Alamofire
import RxSwift
import RxCocoa

struct KaraokeIntervalProgressViewModel {
    var startValue: Float
    var endValue: Float
    var color: UIColor
}

struct KaraokeIntervalsProgressViewModel {

    let id: Int
    let intervals: [KaraokeIntervalProgressViewModel]

}

final class PlayerViewModel: NSObject {

    // MARK: - Public properties -
    var playerItemDurationString: Driver<String> {
        return appState.distinctUntilChanged { $0.player.currentItem?.activeTrackHash == $1.player.currentItem?.activeTrackHash }
            .map { newState in
                guard let duration = newState.currentTrack?.track.audioFile?.duration else {
                    return "--:--"
                }
                
                return TimeInterval(duration).stringFormatted()
            }
    }
    
    var playerItemCurrentTimeString: Driver<String> {
        
        return appState
            .map { $0.player.currentItem?.state }
            .notNil()
            .distinctUntilChanged()
            .map { $0.progress.stringFormatted() }
        
    }

    var playerItemProgressValue: Driver<Float> {
        
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

    var playerItemRestrictedValue: Driver<Float> {
        
        return appState
            .distinctUntilChanged { $0.currentTrack == $1.currentTrack &&
                                    $0.user.profile == $1.user.profile }
            .map { newState in
        
                guard let track = newState.currentTrack?.track,
                      let audio = track.audioFile else { return 0 }
                
                let option = TrackPreviewOptionViewModel(type: .init(with: track,
                                                                     user: newState.user,
                                                                     μSecondsPlayed: nil))
                
                if case .limitSeconds(let x) = option.type {
                    return Float(x) / Float(audio.duration)
                }
                
                return 0
        
            }

    }

    var playerItemNameString: Driver<String> {
        
        return appState.map { $0.activePlayable }
            .distinctUntilChanged()
            .map { i in
                
                guard let x = i else { return "" }
                
                switch x {
                case .addon(let a): return a.type.title
                case .track(let t): return t.name
                case .minusOneTrack(let t): return "\(t.name)"
                case .stub(_, let t): return t
                }
                
            }
        
    }

    var playerItemArtistNameString: Driver<String> {
        
        return appState
            .distinctUntilChanged { $0.currentTrack == $1.currentTrack }
            .map { $0.currentTrack?.track.artist.name ?? "" }
        
    }

    var playerItemTrackLikeState: Driver<Track.LikeStates> {
        return appState
            .map { newState in
                
                guard let currentTrack = newState.currentTrack else { return .none }
                
                return newState.user.likeState(for: currentTrack.track)
            }
    }
    
    var separatorHidden: Driver<Bool> {
        return Driver.combineLatest(playerItemArtistNameString, playerItemNameString) {
            $0.isEmpty || $1.isEmpty
        }
    }

    var canChangePlayerItemTrackLikeState: Driver<Bool> {
        return appState.map { $0.activePlayable != nil }
    }
    var canChangePlayState: Driver<Bool> {
        return appState.map { $0.activePlayable != nil }
    }
    
    var preview: Driver<TrackPreviewOptionViewModel?> {
        

        return appState
            .distinctUntilChanged { $0.currentTrack == $1.currentTrack &&
                                    $0.user.profile == $1.user.profile }
            .flatMapLatest { (newState) in
                
                guard let track = newState.currentTrack?.track else { return .just(nil) }
                
                let option = TrackPreviewOptionViewModel(type: .init(with: track,
                                                                     user: newState.user,
                                                                     μSecondsPlayed: nil))
                
                guard case .fullLimitTimes = option.type else {
                    return .just(option)
                }
                
                return appState.map { $0.player.tracks.previewTime[track.id] }
                    .distinctUntilChanged()
                    .map { time in
                        
                        return TrackPreviewOptionViewModel(type: .init(with: track,
                                                                       user: newState.user,
                                                                       μSecondsPlayed: time))
                        
                }
                
        }
        
    }

    let previewOptionHintText = BehaviorRelay<String?>(value: nil)
    
    var isPlayerBlocked: Driver<Bool> {
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

    var isPlaying: Driver<Bool> {
        return appState.map { $0.player.currentItem?.state.isPlaying }
                    .notNil()
                    .distinctUntilChanged()
    }

    var canForward: Driver<Bool> {
        return appState.distinctUntilChanged { $0.player.currentItem == $1.player.currentItem }
            .map { $0.canForward }
    }
    var canBackward: Driver<Bool> {
        return appState.distinctUntilChanged { $0.player.currentItem == $1.player.currentItem }
            .map { $0.canBackward }
    }

    var canSetPlayerItemProgress: Driver<Bool> {
        return appState.distinctUntilChanged { $0.player.currentItem == $1.player.currentItem }
                       .map { $0.canSeek }
    }

    var canFollowArtist: Driver<Bool> {
        return appState.map { $0.currentTrack != nil }
    }

    var isArtistFollowed: Driver<Bool> {
        
        return appState.map { newState in
            
                guard let artist = newState.currentTrack?.track.artist else { return false }
                
                return newState.user.isFollower(for: artist.id)
            }
    }

    var canNavigate: Driver<Bool> {
        return appState.distinctUntilChanged { $0.currentTrack == $1.currentTrack }
            .map { $0.currentTrack != nil }
    }
    
    var karaokeEnabled: Driver<Bool> {
        return appState.map { $0.player.currentItem?.lyrics?.data.karaoke != nil }
    }
    
    var karaokeIntervalsViewModel: Driver<KaraokeIntervalsProgressViewModel?> {
        
        return appState.map { ($0.player.currentItem?.lyrics, $0.currentTrack?.track.audioFile?.duration) }
            .distinctUntilChanged({ (lhs: (PlayerState.Lyrics?, Int?), rhs: (PlayerState.Lyrics?, Int?)) -> Bool in
                return lhs.0 == rhs.0 && lhs.1 == rhs.1
            })
            .map { (maybeLyrics, maybeDuration) in

                guard let lyrics = maybeLyrics,
                      let karaoke = lyrics.data.karaoke,
                      let duration = maybeDuration,
                      case .karaoke(_) = lyrics.mode else {
                    return nil
                }

                let d = TimeInterval(duration)
                
                let karaokeIntervalViewModels = karaoke.intervals
                    .compactMap { x -> KaraokeIntervalProgressViewModel? in
                        guard !x.content.isEmpty else { return nil }
                        
                        return KaraokeIntervalProgressViewModel(startValue: Float(x.range.lowerBound / d),
                                                                endValue: Float(x.range.upperBound / d),
                                                                color: #colorLiteral(red: 0.9725490196, green: 0.9058823529, blue: 0.1098039216, alpha: 1))
                    }
                
                return KaraokeIntervalsProgressViewModel(id: karaoke.id, intervals: karaokeIntervalViewModels)
                
            }
        
    }
    
    // MARK: - Private properties -

    private(set) weak var router: PlayerRouter?
    
    let disposeBag = DisposeBag()

    // MARK: - Lifecycle -

    init(router: PlayerRouter) {
        self.router = router

        super.init()
        
        preview.map { $0?.hintText }
            .drive(previewOptionHintText)
            .disposed(by: disposeBag)
    }


    func playerItemDescriptionAttributedText(for traitCollection: UITraitCollection) -> NSAttributedString {
        guard let currentTrack = appStateSlice.currentTrack?.track else {
            return NSAttributedString()
        }

        let currentTrackName = currentTrack.name + (traitCollection.horizontalSizeClass == .regular ?  "\n" : " - ")
        let descriptionAttributedString = NSMutableAttributedString(string: currentTrackName,
                                                                    attributes: [NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.760392487, green: 0.7985035777, blue: 0.9999999404, alpha: 0.96),
                                                                                 NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12.0)])

        descriptionAttributedString.append(NSAttributedString(string: currentTrack.artist.name,
                                                              attributes: [NSAttributedString.Key.foregroundColor : #colorLiteral(red: 1, green: 0.3632884026, blue: 0.7128098607, alpha: 0.96),
                                                                           NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12.0)]))

        return descriptionAttributedString
    }



    // MARK: - Actions -

    func play() {
        Dispatcher.dispatch(action: AudioPlayer.Play())
        
    }

    func pause() {
        Dispatcher.dispatch(action: AudioPlayer.Pause())
        
    }

    func forward() {
        Dispatcher.dispatch(action: ProceedToNextItem())
    }

    func backward() {
        Dispatcher.dispatch(action: GetBackToPreviousItem())
    }

    func toggleLike() {
        guard let track = appStateSlice.currentTrack?.track else { return }
        guard !appStateSlice.user.isGuest else { 
            //self.routeToAuthorization();
            return
        }

        UserManager.update(track: track, likeState: .liked).subscribe()
        
    }

    func toggleDislike() {
        guard let track = appStateSlice.currentTrack?.track else { return }
        guard !appStateSlice.user.isGuest else {
            //self.routeToAuthorization();
            return
        }

        UserManager.update(track: track, likeState: .disliked).subscribe()
        
    }

    func setPlayerItemProgress(progress: Float) {
        Dispatcher.dispatch(action: ScrubToFraction(fraction: progress))
    }

    func toggleArtistFollowing() {

        guard let track = appStateSlice.currentTrack?.track else { return }
        guard !appStateSlice.user.isGuest else {
//            self.routeToAuthorization();
            return
        }
        
        UserManager.follow(shouldFollow: !appStateSlice.user.isFollower(for: track.artist.id),
                                artistId: track.artist.id)
            .subscribe()
    }

}

extension PlayerViewModel {

    func application( didChangeUserProfile followedArtistsIds: [String], with artistFollowingState: ArtistFollowingState) {
        guard let artist = appStateSlice.currentTrack?.track.artist, artist.id == artistFollowingState.artistId else { return }
        
        
    }

}
