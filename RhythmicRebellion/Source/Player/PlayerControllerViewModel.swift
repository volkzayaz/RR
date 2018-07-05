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
        guard let playerItemDuration = self.player.playerCurrentItemDuration else { return "--:--"}
        return playerItemDuration.stringFormatted();
    }
    
    var playerItemCurrentTimeString: String {
        guard let playerItemCurrentTime = self.player.playerCurrentItemCurrentTime else { return "--:--"}
        return playerItemCurrentTime.stringFormatted();
    }

    var playerItemProgress: Float {
        guard let playerItemDuration = self.player.playerCurrentItemDuration, playerItemDuration != 0.0,
            let playerItemCurrentTime = self.player.playerCurrentItemCurrentTime else { return 0.0 }

        return Float(playerItemCurrentTime / playerItemDuration)
    }

    var isPlaying: Bool { return self.player.isPlaying }

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerViewModelDelegate?
    private(set) weak var router: PlayerRouter?
    
    private(set) var player: Player

    // MARK: - Lifecycle -

    init(router: PlayerRouter, player: Player) {
        self.router = router
        self.player = player

        super.init()

        self.player.addObserver(self)
    }

    deinit {
        self.player.removeObserver(self)
    }

    func load(with delegate: PlayerViewModelDelegate) {
        self.delegate = delegate


//        let commandCenter = MPRemoteCommandCenter.shared()
//
//        // Add handler for Play Command
//        commandCenter.playCommand.addTarget { [unowned self] event in
//
//            print("webSocketIsConnected: \(self.webSocketService.webSocket.isConnected)")
//
//            if self.player.rate == 0.0 {
//                self.shouldStartPlay = true
//                self.player.play()
//
//                return .success
//            }
//            return .commandFailed
//        }
//
//        // Add handler for Pause Command
//        commandCenter.pauseCommand.addTarget { [unowned self] event in
//            if self.player.rate == 1.0 {
//                self.player.pause()
//                self.shouldStartPlay = false
//                return .success
//            }
//            return .commandFailed
//        }
//
//        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
//
//            self.forward()
//            return .success
//        }
    }

    func startObservePlayer() {
        self.player.addObserver(self)
    }

    func stopObservePlayer() {
        self.player.removeObserver(self)
    }


    func playerItemDescriptionAttributedText(for traitCollection: UITraitCollection) -> NSAttributedString {
        guard let currentTrack = self.player.currentTrack else { return NSAttributedString() }

        let currentTrackArtistName = currentTrack.artist.name + (traitCollection.horizontalSizeClass == .regular ?  "\n" : " - ")
        let descriptionAttributedString = NSMutableAttributedString(string: currentTrackArtistName,
                                                                    attributes: [NSAttributedStringKey.foregroundColor : #colorLiteral(red: 0.760392487, green: 0.7985035777, blue: 0.9999999404, alpha: 0.96),
                                                                                 NSAttributedStringKey.font : UIFont.systemFont(ofSize: 12.0)])

        descriptionAttributedString.append(NSAttributedString(string: currentTrack.name,
                                                              attributes: [NSAttributedStringKey.foregroundColor : #colorLiteral(red: 1, green: 0.3639442921, blue: 0.7127844095, alpha: 0.96),
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

}

extension PlayerControllerViewModel: PlayerObserver {

    func player(player: Player, didChangeStatus status: PlayerStatus) {
        self.delegate?.refreshUI()
    }

    func player(player: Player, didChangePlayState isPlaying: Bool) {
        self.delegate?.refreshUI()
    }

    func player(player: Player, didChangePlayerItem track: Track) {
        self.delegate?.refreshUI()
    }

    func player(player: Player, didChangePlayerItemCurrentTime Time: TimeInterval) {
        self.delegate?.refreshProgressUI()
    }

}

