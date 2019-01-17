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

final class PlayerControllerViewModel: NSObject, PlayerViewModel {

    // MARK: - Public properties -
    var playerItemDurationString: String {
        guard let playerItemDuration = self.player.currentItemDuration else { return "--:--"}
        return playerItemDuration.stringFormatted();
    }
    
    var playerItemCurrentTimeString: String {
        guard let playerItemCurrentTime = self.player.currentItemTime else { return "--:--"}
        return playerItemCurrentTime.stringFormatted();
    }

    var playerItemProgressValue: Float {
        guard let playerItemDuration = self.player.currentItemDuration, playerItemDuration != 0.0,
            let playerItemCurrentTime = self.player.currentItemTime else { return 0.0 }

        return Float(playerItemCurrentTime / playerItemDuration)
    }

    var playerItemRestrictedValue: Float {
        guard let playerItemDuration = self.player.currentItemDuration, playerItemDuration != 0.0,
            let playerItemRestrictedTime = self.player.currentItemRestrictedTime else { return 0.0 }

        return Float(playerItemRestrictedTime / playerItemDuration)
    }

    var playerItemNameString: String {
        guard let playerCurrentQueueItem = self.player.currentQueueItem else { return "" }

        switch playerCurrentQueueItem.content {
        case .addon(let addon):
            return addon.type.title
        case .track(let track):
            return track.name
        case .stub(_):
            return self.player.currentItem?.playlistItem.track.name ?? ""

        }
    }

    var playerItemNameAttributedString: NSAttributedString {
        return NSMutableAttributedString(string: self.playerItemNameString,
                                         attributes: [NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.760392487, green: 0.7985035777, blue: 0.9999999404, alpha: 0.96),
                                                      NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12.0)])
    }

    var playerItemArtistNameString: String {
        guard let currentTrack = self.player.currentItem?.playlistItem.track else { return "" }
        return currentTrack.artist.name
    }

    var playerItemArtistNameAttributedString: NSAttributedString {
        return NSAttributedString(string: self.playerItemArtistNameString,
                                  attributes: [NSAttributedString.Key.foregroundColor : #colorLiteral(red: 1, green: 0.3639442921, blue: 0.7127844095, alpha: 0.96),
                                               NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12.0)])
    }

    var playerItemTrackLikeState: Track.LikeStates {
        guard let user = self.application.user, let currentPlayerItem = self.player.currentItem else { return .none }
        return user.likeState(for: currentPlayerItem.playlistItem.track)
    }

    var canChangePlayerItemTrackLikeState: Bool {
        return self.player.currentItem != nil
    }

    var playerItemPreviewOptionViewModel: TrackPreviewOptionViewModel?

    var isPlayerBlocked: Bool { return self.player.state.blocked }

    var canChangePlayState: Bool { return self.player.currentItem != nil }
    var isPlaying: Bool { return self.player.isPlaying }

    var canForward: Bool { return self.player.canForward }
    var canBackward: Bool { return self.player.canBackward }

    var canSetPlayerItemProgress: Bool { return self.player.canSeek }

    var canFollowArtist: Bool { return self.player.currentItem != nil }

    var isArtistFollowed: Bool {
        guard let user = self.application.user, let currentPlayerItem = self.player.currentItem else { return false }

        return user.isFollower(for: currentPlayerItem.playlistItem.track.artist.id)
    }

    var isKaraokeEnabled: Bool { return self.lyricsKaraokeService.mode.value == .karaoke }
    var karaoke: Karaoke?
    var karaokeModelId: Int? { return self.karaoke?.id }


    // MARK: - Private properties -

    private(set) weak var delegate: PlayerViewModelDelegate?
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

    func load(with delegate: PlayerViewModelDelegate) {

        self.loadPlayerItemPreviewOptionViewModel()
        self.delegate = delegate

        self.lyricsKaraokeService.lyricsState.subscribe(onNext: { [unowned self] (lyricsState) in

            switch lyricsState {
            case .lyrics(let lyrics):
                self.karaoke = lyrics.karaoke
            default:
                self.karaoke = nil
            }

            self.delegate?.refreshKaraokeUI()
            })
            .disposed(by: disposeBag)


        self.delegate?.refreshUI()

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
        self.player.play()
    }

    func pause() {
        self.player.pause()
    }

    func forward() {
        self.player.playForward()
    }

    func backward() {
        self.player.playBackward()
    }

    func toggleLike() {
        guard let track = self.player.currentItem?.playlistItem.track else { return }
        guard (self.application.user as? FanUser) != nil else { self.routeToAuthorization(); return }

        self.application.update(track: track, likeState: .liked) { [weak self] (error) in
            guard let error = error else { return }
            self?.delegate?.show(error: error)
        }
    }

    func toggleDislike() {
        guard let track = self.player.currentItem?.playlistItem.track else { return }
        guard (self.application.user as? FanUser) != nil else { self.routeToAuthorization(); return }

        self.application.update(track: track, likeState: .disliked) { [weak self] (error) in
            guard let error = error else { return }
            self?.delegate?.show(error: error)
        }
    }

    func setPlayerItemProgress(progress: Float) {

        guard self.player.canSeek, let playerItemDuration = self.player.playerCurrentItemDuration, playerItemDuration != 0.0 else { return }

        self.player.seek(to: TimeInterval(playerItemDuration * Double(progress)).rounded())
    }

    func toggleArtistFollowing() {

        guard let currentPlayerItem = self.player.currentItem else { return }
        guard let fanUser = self.application.user as? FanUser else { self.routeToAuthorization(); return }

        let followingCompletion: (Result<[String]>) -> Void = { [weak self] (followingResult) in

            switch followingResult {
            case .failure(let error):
                self?.delegate?.show(error: error)
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

extension PlayerControllerViewModel: PlayerWatcher {

    func playerDidChangePlaylist(player: Player) {
        self.delegate?.refreshUI()
    }

    func player(player: Player, didChange status: PlayerStatus) {
        self.loadPlayerItemPreviewOptionViewModel()
        self.delegate?.refreshUI()
    }

    func player(player: Player, didChangePlayState isPlaying: Bool) {
        self.delegate?.refreshUI()
    }

    func player(player: Player, didChangePlayerItem playerItem: PlayerItem?) {
        self.loadPlayerItemPreviewOptionViewModel()

        if self.karaoke?.trackId != playerItem?.playlistItem.track.id {
            self.karaoke = nil
        }

        self.delegate?.refreshUI()
    }

    func player(player: Player, didChangePlayerQueueItem playerQueueItem: PlayerQueueItem) {
        self.delegate?.refreshUI()
    }

    func player(player: Player, didChangePlayerItemCurrentTime time: TimeInterval) {
        self.delegate?.refreshProgressUI()
    }

    func player(player: Player, didChangePlayerItemTotalPlayTime time: TimeInterval) {
        self.loadPlayerItemPreviewOptionViewModel()
        self.delegate?.refreshUI()
    }

    func player(player: Player, didChangeBlockedState isBlocked: Bool) {
        self.delegate?.refreshUI()
    }
}

extension PlayerControllerViewModel: ApplicationWatcher {

    func application(_ application: Application, didChangeUserProfile followedArtistsIds: [String], with artistFollowingState: ArtistFollowingState) {
        guard let artist = self.player.currentItem?.playlistItem.track.artist, artist.id == artistFollowingState.artistId else { return }
        self.loadPlayerItemPreviewOptionViewModel()
        self.delegate?.refreshUI()
    }

    func application(_ application: Application, didChangeUserProfile tracksLikeStates: [Int : Track.LikeStates], with trackLikeState: TrackLikeState) {
        guard let track = self.player.currentItem?.playlistItem.track, track.id == trackLikeState.id else { return }
        self.delegate?.refreshUI()
    }
}
