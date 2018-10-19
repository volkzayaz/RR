//
//  PlayList.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct PlayerPlaylistItem {

    let track: Track
    let playlistLinkedItem: PlayerPlaylistLinkedItem
}

class PlayerPlaylist {    

    private(set) var tracks = Set<Track>()
    private(set) var playlistLinkedItems = [String : PlayerPlaylistLinkedItem]()
    private(set) var tracksAddons = [Int : Set<Addon>]()
    private(set) var tracksTotalPlayMSeconds = [Int : UInt64]()

    // MARK: - Tracks -
    var orderedPlaylistItems: [PlayerPlaylistItem] {
        var orderedPlaylistItems: [PlayerPlaylistItem] = [PlayerPlaylistItem]()
        var currentPlaylistLinkedItem: PlayerPlaylistLinkedItem? = self.firstPlaylistLinkedItem

        while currentPlaylistLinkedItem != nil {
            if let track = self.tracks.filter({ return $0.id == currentPlaylistLinkedItem!.trackId }).first {
                let playlistItem = PlayerPlaylistItem(track: track, playlistLinkedItem: currentPlaylistLinkedItem!)
                orderedPlaylistItems.append(playlistItem)
            }

            guard let nextKey = currentPlaylistLinkedItem?.nextKey, let nextPlaylistLinkedItem = self.playlistLinkedItems[nextKey] ?? nil else { break }
            currentPlaylistLinkedItem = nextPlaylistLinkedItem
        }

        return orderedPlaylistItems
    }

    func reset(tracks: [Track]) {
        self.tracks = Set(tracks)
        self.playlistLinkedItems.removeAll()
        self.resetAddons()
    }

    func add(traksToAdd: [Track]) {
        self.tracks = self.tracks.union(Set(traksToAdd))
    }

    func playListItem(for trackId: TrackId?) -> PlayerPlaylistItem? {
        guard let trackKey = trackId?.key, let playlistLinkedItem = self.playlistLinkedItems[trackKey] else { return nil }

        return self.playlistItem(for: playlistLinkedItem)
    }


    func playlistItem(for playlistLinkedItem: PlayerPlaylistLinkedItem) -> PlayerPlaylistItem? {
        if let track = self.tracks.filter({ return $0.id == playlistLinkedItem.trackId }).first {
            return PlayerPlaylistItem(track: track, playlistLinkedItem: playlistLinkedItem)
        }
        return nil
    }

    func contains(track: Track) -> Bool {
        return self.tracks.contains(track)
    }

    // MARK: - PlayerPlaylistItem -
    var firstPlayListItem: PlayerPlaylistItem? {
        guard let firstPlayListLinkedItem = self.firstPlaylistLinkedItem else { return nil }
        return self.playlistItem(for: firstPlayListLinkedItem)
    }

    var lastPlayListItem: PlayerPlaylistItem? {
        guard let lastPlayListLinkedItem = self.lastPlaylistLinkedItem else { return nil }
        return self.playlistItem(for: lastPlayListLinkedItem)
    }

    func nextPlaylistItem(for playlistItem: PlayerPlaylistItem) -> PlayerPlaylistItem? {
        guard let playlistLinkedItemNextKey = playlistItem.playlistLinkedItem.nextKey ?? self.firstPlaylistLinkedItem?.key,
            let nextPlaylistLinkedItem = self.playlistLinkedItems[playlistLinkedItemNextKey] else { return nil }

        return self.playlistItem(for: nextPlaylistLinkedItem)
    }

    func previousPlaylistItem(for playlistItem: PlayerPlaylistItem) -> PlayerPlaylistItem? {
        guard let playlistLinkedItemPreviousKey = playlistItem.playlistLinkedItem.previousKey ?? self.lastPlaylistLinkedItem?.key,
            let previousPlaylistLinkedItem = self.playlistLinkedItems[playlistLinkedItemPreviousKey] else { return nil }

        return self.playlistItem(for: previousPlaylistLinkedItem)
    }

    // MARK: - PlayerPlaylistLinkedItem -
    var firstPlaylistLinkedItem: PlayerPlaylistLinkedItem? {
        guard let firstPlayListItem = self.playlistLinkedItems.filter( { return $0.value.previousKey == nil }).first else { return nil }
        return firstPlayListItem.value
    }

    var lastPlaylistLinkedItem: PlayerPlaylistLinkedItem? {
        guard let lastPlayListItem = self.playlistLinkedItems.filter( { return $0.value.nextKey == nil }).first else { return nil }
        return lastPlayListItem.value
    }

    func playlistLinkedItem(for trackId: TrackId?) -> PlayerPlaylistLinkedItem? {
        guard let trackKey = trackId?.key else { return nil }
        return self.playlistLinkedItems[trackKey] ?? nil
    }

    func nextPlaylistLinkedItem(for playlistLinkedItem: PlayerPlaylistLinkedItem) -> PlayerPlaylistLinkedItem? {
        guard let playlistLinkedItemNextKey = playlistLinkedItem.nextKey,
            let nextPlaylistLinkedItem = self.playlistLinkedItems[playlistLinkedItemNextKey] else { return nil }

        return nextPlaylistLinkedItem
    }

    func previousPlaylistLinkedItem(for playlistLinkedItem: PlayerPlaylistLinkedItem) -> PlayerPlaylistLinkedItem? {
        guard let playlistItemPreviousKey = playlistLinkedItem.previousKey,
            let previousPlaylistLinkedItem = self.playlistLinkedItems[playlistItemPreviousKey] else { return nil }

        return previousPlaylistLinkedItem
    }

    func reset(playlistLinkedItems: [String : PlayerPlaylistLinkedItem?]) {

        self.playlistLinkedItems.removeAll()

        playlistLinkedItems.forEach { (key, linkedItem) in
            guard let linkedItem = linkedItem else { return }
            self.playlistLinkedItems[key] = linkedItem
        }
    }

    func add(playlistLinkedItems: [String : PlayerPlaylistLinkedItem?]) {

        playlistLinkedItems.forEach { (key, linkedItem) in
            guard let linkedItem = linkedItem else { return  }
            self.playlistLinkedItems[key] = linkedItem
        }
    }
    
    func update(playlistLinkedItems: [String : PlayerPlaylistLinkedItem?]) {

        playlistLinkedItems.forEach { (key, linkedItem) in
            guard let linkedItem = linkedItem else { self.playlistLinkedItems.removeValue(forKey: key); return }
            self.playlistLinkedItems[key] = linkedItem
        }
    }

    func generateLinkedKeyKey() -> String {

        var key: String = String(randomWithLength: 5, allowedCharacters: .alphaNumeric)

        while self.playlistLinkedItems[key] != nil {
            key = String(randomWithLength: 5, allowedCharacters: .alphaNumeric)
        }

        return key
    }

    func makePlaylistLinkedItem(for track: Track) -> PlayerPlaylistLinkedItem {

        let key = self.generateLinkedKeyKey()

        return PlayerPlaylistLinkedItem(trackId: track.id, key: key)

    }

    // MARK: - Addons -

    func resetAddons() {
        self.tracksAddons.removeAll()
    }

    func add(tracksAddons: [Int : [Addon]]) {

        for (trackId, addons) in tracksAddons  {
            guard let currentAddons = self.tracksAddons[trackId] else {
                self.tracksAddons[trackId] = Set(addons)
                continue
            }

            self.tracksAddons[trackId] = currentAddons.union(Set(addons))
        }
    }

    func addons(for track: Track) -> [Addon]? {
        guard let trackAddons = self.tracksAddons[track.id] else { return nil }

        return Array(trackAddons)
    }

    func addons(for track: Track, addonsIds: [Int]) -> [Addon]? {
        guard let allAddons = self.tracksAddons[track.id] else { return nil }

        return allAddons.filter{ addonsIds.contains($0.id) } 

//        var addons = [Addon]()
//        for addonId in addonsIds {
//            guard let addon = allAddons.filter({ return $0.id == addonId }).first else { continue }
//            addons.append(addon)
//        }
//
//        return addons
    }

    func addonsStates(for track: Track) -> [AddonState]? {
        return self.tracksAddons[track.id]?.map({ (addon) -> AddonState in
            return AddonState(id: addon.id, typeValue: addon.typeValue, trackId: track.id)
        })
    }

    // MARK: Preview

    func reset(tracksTotalPlayMSeconds: [Int : UInt64]) {
        self.tracksTotalPlayMSeconds = tracksTotalPlayMSeconds
    }

    func update(tracksTotalPlayMSeconds: [Int : UInt64]) {
        self.tracksTotalPlayMSeconds += tracksTotalPlayMSeconds
    }

    func totalPlayMSeconds(for track: Track) -> UInt64? {
        return self.tracksTotalPlayMSeconds[track.id]
    }
}
