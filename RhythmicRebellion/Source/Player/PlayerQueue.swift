//
//  PlayerQueue.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/12/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import AVFoundation

class PlayerQueueItem {

    enum Content {
        case addon(Addon)
        case track(Track)
    }

    let content: Content

    init(with addon: Addon) {
        self.content = .addon(addon)
    }

    init(with track: Track) {
        self.content = .track(track)
    }
}

class PlayerQueue {

    var track: PlayerTrack?
    var addons: [Addon]?

    var isReadyToPlay: Bool {
        return self.addons != nil
    }

    var containsOnlyTrack: Bool {
        return self.addons?.isEmpty ?? true && self.playerItems.isEmpty == false
    }

    var isEmpty: Bool {
        return self.playerItems.isEmpty
    }

    var currentItem: PlayerQueueItem? {
        guard let playerItem = self.playerItems.first, let urlAsset = playerItem.asset as? AVURLAsset else { return nil }
        return self.itemsInfo[urlAsset.url.absoluteString]
    }


    private var itemsInfo = [String : PlayerQueueItem]()
    private(set) var playerItems = [AVPlayerItem]()

    private func makeItems() {

        self.itemsInfo.removeAll()
        self.playerItems.removeAll()

        for addon in self.addons ?? [] {
            guard let playerItemURL = URL(string: addon.audioFile.urlString) else { continue }
            itemsInfo[addon.audioFile.urlString] = PlayerQueueItem(with: addon)
            playerItems.append(AVPlayerItem(url: playerItemURL))
        }

        if let track = self.track?.track, let audioFile = track.audioFile, let playerItemURL = URL(string: audioFile.urlString) {
            itemsInfo[audioFile.urlString] = PlayerQueueItem(with: track)
            playerItems.append(AVPlayerItem(url: playerItemURL))
        }
    }

    func replace(track: PlayerTrack, addons: [Addon]? = nil) {

        self.track = track
        self.addons = addons

        self.makeItems()
    }

    func replace(addons: [Addon]) {

        self.addons = addons
        self.makeItems()
    }

    func dequeueFirst() {
        guard self.playerItems.isEmpty == false else { return }
        let playerItem = self.playerItems.removeFirst()
        guard let urlAsset = playerItem.asset as? AVURLAsset else { return }
        guard let queueItem = self.itemsInfo.removeValue(forKey: urlAsset.url.absoluteString) else { return }

        switch queueItem.content {
        case .addon(let addon):
            if let addonIndex = self.addons?.index(of: addon) {
                self.addons?.remove(at: addonIndex)
            }

        default: break
        }
    }
}
