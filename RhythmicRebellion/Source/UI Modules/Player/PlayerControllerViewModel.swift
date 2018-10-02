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
                                         attributes: [NSAttributedStringKey.foregroundColor : #colorLiteral(red: 0.760392487, green: 0.7985035777, blue: 0.9999999404, alpha: 0.96),
                                                      NSAttributedStringKey.font : UIFont.systemFont(ofSize: 12.0)])
    }

    var playerItemArtistNameString: String {
        guard let currentTrack = self.player.currentItem?.playlistItem.track else { return "" }
        return currentTrack.artist.name
    }

    var playerItemArtistNameAttributedString: NSAttributedString {
        return NSAttributedString(string: self.playerItemArtistNameString,
                                  attributes: [NSAttributedStringKey.foregroundColor : #colorLiteral(red: 1, green: 0.3639442921, blue: 0.7127844095, alpha: 0.96),
                                               NSAttributedStringKey.font : UIFont.systemFont(ofSize: 12.0)])
    }

    var playerItemPreviewOptionsImage: UIImage? {
        guard let track = self.player.currentItem?.playlistItem.track else { return nil }

        return self.trackPreviewOptionsImageGenerator.image(for: track,
                                                            trackTotalPlayMSeconds: self.player.totalPlayMSeconds(for: track),
                                                            user: self.application.user)?.withRenderingMode(.alwaysTemplate)
    }

    var isPlayerBlocked: Bool { return self.player.isBlocked }
    var isPlaying: Bool { return self.player.isPlaying }

    var canForward: Bool {
        return self.player.canForward
    }

    var canBackward: Bool {
        return self.player.canBackward
    }

    var canSetPlayerItemProgress: Bool {
        return self.player.canSeek
    }

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerViewModelDelegate?
    private(set) weak var router: PlayerRouter?
    private(set) var application: Application
    private(set) var player: Player

    private(set) var trackPreviewOptionsImageGenerator: TrackPreviewOptionsImageGenerator

    // MARK: - Lifecycle -

    init(router: PlayerRouter, application: Application, player: Player) {
        self.router = router
        self.application = application
        self.player = player

        self.trackPreviewOptionsImageGenerator = TrackPreviewOptionsImageGenerator(font: UIFont.systemFont(ofSize: 14.0))

        super.init()
    }

    deinit {
        self.player.removeObserver(self)
    }

    func load(with delegate: PlayerViewModelDelegate) {
        self.delegate = delegate
    }

    func startObservePlayer() {
        self.player.addObserver(self)
    }

    func stopObservePlayer() {
        self.player.removeObserver(self)
    }

    func playerItemDescriptionAttributedText(for traitCollection: UITraitCollection) -> NSAttributedString {
        guard let currentTrack = self.player.currentItem?.playlistItem.track else { return NSAttributedString() }

        let currentTrackName = currentTrack.name + (traitCollection.horizontalSizeClass == .regular ?  "\n" : " - ")
        let descriptionAttributedString = NSMutableAttributedString(string: currentTrackName,
                                                                    attributes: [NSAttributedStringKey.foregroundColor : #colorLiteral(red: 0.760392487, green: 0.7985035777, blue: 0.9999999404, alpha: 0.96),
                                                                                 NSAttributedStringKey.font : UIFont.systemFont(ofSize: 12.0)])

        descriptionAttributedString.append(NSAttributedString(string: currentTrack.artist.name,
                                                              attributes: [NSAttributedStringKey.foregroundColor : #colorLiteral(red: 1, green: 0.3632884026, blue: 0.7128098607, alpha: 0.96),
                                                                           NSAttributedStringKey.font : UIFont.systemFont(ofSize: 12.0)]))

        return descriptionAttributedString
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

    func setPlayerItemProgress(progress: Float) {

        guard self.player.canSeek, let playerItemDuration = self.player.playerCurrentItemDuration, playerItemDuration != 0.0 else { return }

        self.player.seek(to: TimeInterval(playerItemDuration * Double(progress)).rounded())
    }
}

extension PlayerControllerViewModel: PlayerObserver {

    func player(player: Player, didChangeStatus status: PlayerStatus) {
        self.delegate?.refreshUI()
    }

    func player(player: Player, didChangePlayState isPlaying: Bool) {
        self.delegate?.refreshUI()
    }

    func player(player: Player, didChangePlayerQueueItem playerQueueItem: PlayerQueueItem) {
        self.delegate?.refreshUI()
    }

    func player(player: Player, didChangePlayerItemCurrentTime Time: TimeInterval) {
        self.delegate?.refreshProgressUI()
    }

    func player(player: Player, didChangeBlockedState isBlocked: Bool) {
        self.delegate?.refreshUI()
    }
}

