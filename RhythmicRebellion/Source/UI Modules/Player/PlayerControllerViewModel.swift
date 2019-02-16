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

struct DefaultKaraokeIntervalProgressViewModel: KaraokeIntervalProgressViewModel {
    var startValue: Float
    var endValue: Float
    var color: UIColor
}

struct DefaultKaraokeIntervalsProgressViewModel: KaraokeIntervalsProgressViewModel {

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

    var playerItemRestrictedValue: Float {
        guard let playerItemDuration = self.player.currentItemDuration, playerItemDuration != 0.0,
            let playerItemRestrictedTime = self.player.currentItemRestrictedTime else { return 0.0 }

        return Float(playerItemRestrictedTime / playerItemDuration)
    }

    var playerItemNameString: Driver<String> {
        
        return appState.map {
            $0.player.currentItem?.musicType
            }
            .distinctUntilChanged()
            .map { i in
                
                guard let x = i else { return "" }
                
                switch x {
                case .addon(let a): return a.type.title
                case .track(let t): return t.name

                    //???
//                case .stub(_):
//                    return self.player.currentItem?.playlistItem.track.name ?? ""
                    
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
                
                guard let user = self.application.user,
                      let currentTrack = newState.currentTrack else { return .none }
                
                return user.likeState(for: currentTrack.track)
            }
    }

    var canChangePlayerItemTrackLikeState: Driver<Bool> {
        return appState.map { $0.player.currentItem?.musicType != nil }
    }
    var canChangePlayState: Driver<Bool> {
        return appState.map { $0.player.currentItem?.musicType != nil }
    }
    
    
    var playerItemPreviewOptionViewModel: TrackPreviewOptionViewModel?

    var isPlayerBlocked: Driver<Bool> {
        return appState.map { $0.player.isBlocked }
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

    var canFollowArtist: Bool { return self.player.currentItem != nil }

    var isArtistFollowed: Driver<Bool> {
        return appState
            .distinctUntilChanged { $0.currentTrack == $1.currentTrack }
            .map { newState in
                
                guard let user = self.application.user,
                      let artist = newState.currentTrack?.track.artist else { return false }
                
                return user.isFollower(for: artist.id)
            }
    }

    var isKaraokeEnabled: Bool { return self.lyricsKaraokeService.mode.value == .karaoke }
    var karaoke: Karaoke?
    var karaokeModelId: Int? { return self.karaoke?.id }


    // MARK: - Private properties -

    private(set) weak var router: PlayerRouter?
    private(set) var application: Application
    private(set) var player: Player
    private(set) var lyricsKaraokeService: LyricsKaraokeService

    private(set) var textImageGenerator: TextImageGenerator

    let disposeBag = DisposeBag()

    // MARK: - Lifecycle -

    init(router: PlayerRouter, application: Application, player: Player, lyricsKaraokeService: LyricsKaraokeService) {
        self.router = router
        self.application = application
        self.player = player
        self.lyricsKaraokeService = lyricsKaraokeService

        self.textImageGenerator = TextImageGenerator(font: UIFont.systemFont(ofSize: 14.0))

        super.init()
    }

    deinit {
        self.player.removeWatcher(self)
        self.application.removeWatcher(self)
    }

    func load() {

        self.loadPlayerItemPreviewOptionViewModel()
        
        self.lyricsKaraokeService.lyricsState.subscribe(onNext: { [unowned self] (lyricsState) in

            switch lyricsState {
            case .lyrics(let lyrics):
                self.karaoke = lyrics.karaoke
            default:
                self.karaoke = nil
            }

            })
            .disposed(by: disposeBag)

        self.player.addWatcher(self)
        self.application.addWatcher(self)
    }

    func routeToAuthorization() {
        self.router?.routeToAuthorization(with: .signIn)
    }

    func playerItemDescriptionAttributedText(for traitCollection: UITraitCollection) -> NSAttributedString {
        guard let currentTrack = self.player.currentItem?.playlistItem.track else { return NSAttributedString() }

        let currentTrackName = currentTrack.name + (traitCollection.horizontalSizeClass == .regular ?  "\n" : " - ")
        let descriptionAttributedString = NSMutableAttributedString(string: currentTrackName,
                                                                    attributes: [NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.760392487, green: 0.7985035777, blue: 0.9999999404, alpha: 0.96),
                                                                                 NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12.0)])

        descriptionAttributedString.append(NSAttributedString(string: currentTrack.artist.name,
                                                              attributes: [NSAttributedString.Key.foregroundColor : #colorLiteral(red: 1, green: 0.3632884026, blue: 0.7128098607, alpha: 0.96),
                                                                           NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12.0)]))

        return descriptionAttributedString
    }

    func loadPlayerItemPreviewOptionViewModel() {

        guard let track = self.player.currentItem?.playlistItem.track else { self.playerItemPreviewOptionViewModel = nil; return }

        self.playerItemPreviewOptionViewModel = TrackPreviewOptionViewModel.Factory().makeViewModel(track: track,
                                                                                                    user: self.application.user,
                                                                                                    player: self.player,
                                                                                                    textImageGenerator: self.textImageGenerator)

    }

    func karaokeIntervalsViewModel() -> DefaultKaraokeIntervalsProgressViewModel? {

        guard self.lyricsKaraokeService.mode.value == .karaoke else { return nil }
        guard let karaoke = self.karaoke, let playerItemDuration = self.player.currentItemDuration else { return nil }

        let karaokeIntervalViewModels: [DefaultKaraokeIntervalProgressViewModel] = karaoke.intervals.compactMap {
            guard $0.content.isEmpty == false else { return nil }

            return DefaultKaraokeIntervalProgressViewModel(startValue: Float($0.start / Double(playerItemDuration)),
                                                           endValue: Float($0.end / Double(playerItemDuration)),
                                                           color: #colorLiteral(red: 0.9725490196, green: 0.9058823529, blue: 0.1098039216, alpha: 1))
        }

        return DefaultKaraokeIntervalsProgressViewModel(id: karaoke.id, intervals: karaokeIntervalViewModels)
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
        guard let track = self.player.currentItem?.playlistItem.track else { return }
        guard (self.application.user as? FanUser) != nil else { self.routeToAuthorization(); return }

        self.application.update(track: track, likeState: .liked) { [weak self] (error) in
            guard let error = error else { return }
            
        }
    }

    func toggleDislike() {
        guard let track = self.player.currentItem?.playlistItem.track else { return }
        guard (self.application.user as? FanUser) != nil else { self.routeToAuthorization(); return }

        self.application.update(track: track, likeState: .disliked) { [weak self] (error) in
            guard let error = error else { return }
            
        }
    }

    func setPlayerItemProgress(progress: Float) {
        DataLayer.get.daPlayer.seek(to: progress)
    }

    func toggleArtistFollowing() {

        guard let currentPlayerItem = self.player.currentItem else { return }
        guard let fanUser = self.application.user as? FanUser else { self.routeToAuthorization(); return }

        let followingCompletion: (Result<[String]>) -> Void = { [weak self] (followingResult) in

            switch followingResult {
            //case .failure(let error):
                
            default: break
            }
        }

        if fanUser.isFollower(for: currentPlayerItem.playlistItem.track.artist.id) {
            self.application.unfollow(artistId: currentPlayerItem.playlistItem.track.artist.id, completion: followingCompletion)
        } else {
            self.application.follow(artistId: currentPlayerItem.playlistItem.track.artist.id, completion: followingCompletion)
        }
    }

    func canNavigate(to playerNavigationItemType: PlayerNavigationItem.NavigationType) -> Bool {
        switch playerNavigationItemType {
        case .lyrics, .promo, .video: return self.player.currentItem != nil
        case .playlist: return true
        }
    }

    func navigate(to playerNavigationItemType: PlayerNavigationItem.NavigationType) {
        self.router?.navigate(to: playerNavigationItemType)
    }
}

extension PlayerViewModel: PlayerWatcher {

    func playerDidChangePlaylist(player: Player) {
        
    }

    func player(player: Player, didChange status: PlayerStatus) {
        self.loadPlayerItemPreviewOptionViewModel()
        
    }

    func player(player: Player, didChangePlayState isPlaying: Bool) {
        
    }

    func player(player: Player, didChangePlayerItem playerItem: PlayerItem?) {
        self.loadPlayerItemPreviewOptionViewModel()

        if self.karaoke?.trackId != playerItem?.playlistItem.track.id {
            self.karaoke = nil
        }

        
    }

    func player(player: Player, didChangePlayerQueueItem playerQueueItem: PlayerQueueItem) {
        
    }

    func player(player: Player, didChangePlayerItemCurrentTime time: TimeInterval) {
        
    }

    func player(player: Player, didChangePlayerItemTotalPlayTime time: TimeInterval) {
        self.loadPlayerItemPreviewOptionViewModel()
        
    }

    func player(player: Player, didChangeBlockedState isBlocked: Bool) {
        
    }
}

extension PlayerViewModel: ApplicationWatcher {

    func application(_ application: Application, didChangeUserProfile followedArtistsIds: [String], with artistFollowingState: ArtistFollowingState) {
        guard let artist = self.player.currentItem?.playlistItem.track.artist, artist.id == artistFollowingState.artistId else { return }
        self.loadPlayerItemPreviewOptionViewModel()
        
    }

    func application(_ application: Application, didChangeUserProfile tracksLikeStates: [Int : Track.LikeStates], with trackLikeState: TrackLikeState) {
        guard let track = self.player.currentItem?.playlistItem.track, track.id == trackLikeState.id else { return }
        
    }
}
