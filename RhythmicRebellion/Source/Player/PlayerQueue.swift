//
//  PlayerQueue.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/12/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

class PlayerQueueItem {

    enum Content {
        case stub(AudioFile)
        case addon(Addon)
        case track(Track)
    }

    let content: Content
    let playerItem: AVPlayerItem

    var isTrack: Bool {
        switch content {
        case .track(_): return true
        default: return false
        }
    }

    init(with addon: Addon, playerItem: AVPlayerItem) {
        self.content = .addon(addon)
        self.playerItem = playerItem
    }

    init(with track: Track, playerItem: AVPlayerItem) {
        self.content = .track(track)
        self.playerItem = playerItem
    }

    init(with stubAudioFile: AudioFile, playerItem: AVPlayerItem) {
        self.content = .stub(stubAudioFile)
        self.playerItem = playerItem
    }


}

class PlayerQueue {

    var playerItem: PlayerItem? { return self.playerItemObservable.value }

    let playerItemObservable: BehaviorRelay<PlayerItem?> = BehaviorRelay(value: nil)
    var addons: [Addon]?

    var prefferedAudioFileType: AudioFileType {
        didSet {
            self.makeItems()
        }
    }

    var isReadyToPlay: Bool {
        return self.addons != nil
    }

    var containsOnlyTrack: Bool {
        return self.addons?.isEmpty ?? true && self.items.isEmpty == false
    }

    var isEmpty: Bool {
        return self.items.isEmpty
    }

    var currentItem: PlayerQueueItem? {
        return self.items.first
    }

    private var items = [PlayerQueueItem]()

    var playerItems: [AVPlayerItem] {
        return self.items.map { $0.playerItem }
    }

    init(prefferedAudioFileType: AudioFileType) {
        self.prefferedAudioFileType = prefferedAudioFileType
    }

    private func makeItems() {

        self.items.removeAll()

        guard self.playerItem?.stubReason == nil else {

            self.addons = []

            if let stubAudioFile = self.playerItem?.stubReason?.audioFile, let playerItemURL = URL(string: stubAudioFile.urlString) {
                self.items.append(PlayerQueueItem(with: stubAudioFile, playerItem: AVPlayerItem(url: playerItemURL)))
            }

            return
        }

        for addon in self.addons ?? [] {
            guard let playerItemURL = URL(string: addon.audioFile.urlString) else { continue }
            self.items.append(PlayerQueueItem(with: addon, playerItem: AVPlayerItem(url: playerItemURL)))
        }

        if let track = self.playerItem?.playlistItem.track {
            if self.prefferedAudioFileType == .clean, let cleanAudioFile = track.cleanAudioFile, let playerItemURL = URL(string: cleanAudioFile.urlString) {
                items.append(PlayerQueueItem(with: track, playerItem: AVPlayerItem(url: playerItemURL)))
            } else if let audioFile = track.audioFile, let playerItemURL = URL(string: audioFile.urlString) {
                items.append(PlayerQueueItem(with: track, playerItem: AVPlayerItem(url: playerItemURL)))
            }
        }
    }

    func reset() {
        self.playerItemObservable.accept(nil)
        self.addons = nil

        self.makeItems()
    }

    func replace(playerItem: PlayerItem?, addons: [Addon]? = nil) {

        self.playerItemObservable.accept(playerItem)
        self.addons = addons

        self.makeItems()
    }

    func replace(addons: [Addon]) {

        self.addons = addons
        self.makeItems()
    }

    func dequeueFirst() {
        guard self.items.isEmpty == false else { return }
        let playerQueueItem = self.items.removeFirst()

        switch playerQueueItem.content {
        case .addon(let addon):
            if let addonIndex = self.addons?.index(of: addon) {
                self.addons?.remove(at: addonIndex)
            }

        default: break
        }
    }
}
