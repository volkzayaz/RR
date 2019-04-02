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
        
        return appState.map { $0.currentTrack }
            .distinctUntilChanged()
            .map { maybeTrack in
                
                guard let track = maybeTrack?.track,
                    let t = track.previewType,
                    let audio = track.audioFile else { return 0 }
                
                switch t {
                case .limit45: return Float(45) / Float(audio.duration)
                case .limit90: return Float(90) / Float(audio.duration)
                default      : return 0
                }
        
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
                case .minusOneTrack(let t): return "Minus one song. \(t.name)"
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
            .distinctUntilChanged { $0.currentTrack == $1.currentTrack }
            .map { newState in
                
                guard let user = newState.user,
                      let currentTrack = newState.currentTrack else { return .none }
                
                return user.likeState(for: currentTrack.track)
            }
    }

    var canChangePlayerItemTrackLikeState: Driver<Bool> {
        return appState.map { $0.activePlayable != nil }
    }
    var canChangePlayState: Driver<Bool> {
        return appState.map { $0.activePlayable != nil }
    }
    
    var preview: Driver<TrackPreviewOptionViewModel?> {
        
        let g = textImageGenerator
        
        //TODO: listen to user changes as well
        
        return appState
            .distinctUntilChanged { $0.currentTrack == $1.currentTrack }
            .flatMapLatest { (newState) in
                
                let currentTrack = newState.currentTrack
                
                guard let track = currentTrack?.track else { return .just(nil) }
                
                guard case .full? = track.previewType else {
                    return .just(TrackPreviewOptionViewModel(previewOptionType: .init(with: track,
                                                                                      user: newState.user, μSecondsPlayed: nil),
                                                             textImageGenerator: g))
                }
                
                return appState.map { $0.player.tracks.previewTime[track.id] }
                    .distinctUntilChanged()
                    .map { time in
                        
                        return TrackPreviewOptionViewModel(previewOptionType: .init(with: track,
                                                                                    user: newState.user, μSecondsPlayed: time),
                                                           textImageGenerator: g)
                        
                }
                
        }
        
    }

    var previewOptionImage: Driver<UIImage?> {
        return preview.map { $0?.image }
    }

    let previewOptionHintText = BehaviorRelay<String?>(value: nil)
    
    var isPlayerBlocked: Driver<Bool> {
        return appState
            .map { state in
                
                guard !state.player.lastChangeSignatureHash.isOwn else {
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
        return appState
            .distinctUntilChanged { $0.currentTrack == $1.currentTrack }
            .map { newState in
                
                guard let user = newState.user,
                      let artist = newState.currentTrack?.track.artist else { return false }
                
                return user.isFollower(for: artist.id)
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
        
        return appState.map { ($0.player.currentItem?.lyrics?.data.karaoke, $0.player.currentItem?.state.progress) }
            .distinctUntilChanged({ (lhs: (Karaoke?, TimeInterval?), rhs: (Karaoke?, TimeInterval?)) -> Bool in
                return lhs.0 == rhs.0 && lhs.1 == rhs.1
            })
            .map { (maybeKaraoke, maybeProgress) in

                guard let karaoke = maybeKaraoke, let progress = maybeProgress else {
                    return nil
                }

                let karaokeIntervalViewModels = karaoke.intervals
                    .compactMap { x -> KaraokeIntervalProgressViewModel? in
                        guard !x.content.isEmpty else { return nil }
                        
                        return KaraokeIntervalProgressViewModel(startValue: Float(x.start / progress),
                                                                endValue: Float(x.end / progress),
                                                                color: #colorLiteral(red: 0.9725490196, green: 0.9058823529, blue: 0.1098039216, alpha: 1))
                    }
                
                return KaraokeIntervalsProgressViewModel(id: karaoke.id, intervals: karaokeIntervalViewModels)
                
            }
        
    }
    
    // MARK: - Private properties -

    private(set) weak var router: PlayerRouter?
    private(set) var application: Application
    
    private(set) var textImageGenerator: TextImageGenerator

    let disposeBag = DisposeBag()

    // MARK: - Lifecycle -

    init(router: PlayerRouter, application: Application) {
        self.router = router
        self.application = application
        
        self.textImageGenerator = TextImageGenerator(font: UIFont.systemFont(ofSize: 14.0))

        super.init()
        
        preview.map { $0?.hintText }
            .drive(previewOptionHintText)
            .disposed(by: disposeBag)
    }

    deinit {
        self.application.removeWatcher(self)
    }

    func load() {
        self.application.addWatcher(self)
    }

    func routeToAuthorization() {
        self.router?.routeToAuthorization(with: .signIn)
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
        DataLayer.get.daPlayer.play()
        
    }

    func pause() {
        DataLayer.get.daPlayer.pause()
        
    }

    func forward() {
        DataLayer.get.daPlayer.skipForward()
    }

    func backward() {
        DataLayer.get.daPlayer.skipBack()
    }

    func toggleLike() {
        guard let track = appStateSlice.currentTrack?.track else { return }
        guard appStateSlice.user?.isGuest ?? false else { self.routeToAuthorization(); return }

        self.application.update(track: track, likeState: .liked).subscribe()
        
    }

    func toggleDislike() {
        guard let track = appStateSlice.currentTrack?.track else { return }
        guard appStateSlice.user?.isGuest ?? false else { self.routeToAuthorization(); return }

        self.application.update(track: track, likeState: .liked).subscribe()
        
    }

    func setPlayerItemProgress(progress: Float) {
        DataLayer.get.daPlayer.seek(to: progress)
    }

    func toggleArtistFollowing() {

        guard let track = appStateSlice.currentTrack?.track else { return }
        guard let user = appStateSlice.user, user.isGuest else { self.routeToAuthorization(); return }
        
        self.application.follow(shouldFollow: !user.isFollower(for: track.artist.id),
                                artistId: track.artist.id)
    }

    func navigate(to playerNavigationItemType: PlayerNavigationItem.NavigationType) {
        self.router?.navigate(to: playerNavigationItemType)
    }
}

extension PlayerViewModel: ApplicationWatcher {

    func application(_ application: Application, didChangeUserProfile followedArtistsIds: [String], with artistFollowingState: ArtistFollowingState) {
        guard let artist = appStateSlice.currentTrack?.track.artist, artist.id == artistFollowingState.artistId else { return }
        
        
    }

}
