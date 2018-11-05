//
//  PlayList.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

class PlayerPlaylistItem {

    let track: Track
    let key: String
    var nextKey: String?
    var previousKey: String?

    init(with track: Track, key: String, nextKey: String? = nil, previousKey: String? = nil) {
        self.track = track

        self.key = key
        self.nextKey = nextKey
        self.previousKey = previousKey
    }

    func apply(path: PlayerPlaylistItemPatch) {
        if let pathNextKey = path.nextKey { self.nextKey = pathNextKey.value }
        if let pathPreviousKey = path.previousKey { self.previousKey = pathPreviousKey.value }
    }

}

extension PlayerPlaylistItem: Equatable {
    static func == (lhs: PlayerPlaylistItem, rhs: PlayerPlaylistItem) -> Bool {
        return lhs.key == rhs.key && lhs.track.id == rhs.track.id
    }
}

class PlayerPlaylist {    

    private(set) var tracks = Set<Track>()
    private(set) var playlistItems = [String : PlayerPlaylistItem]()
    private(set) var reservedPlaylistItemsKeys = Set<String>()
    private(set) var tracksAddons = [Int : Set<Addon>]()
    private(set) var tracksTotalPlayMSeconds = [Int : UInt64]()

    // MARK: - Tracks -
    var orderedPlaylistItems: [PlayerPlaylistItem] {
        var orderedPlaylistItems: [PlayerPlaylistItem] = [PlayerPlaylistItem]()
        var currentPlaylistItem: PlayerPlaylistItem? = self.firstPlaylistItem

        while currentPlaylistItem != nil && currentPlaylistItem != orderedPlaylistItems.first {
            orderedPlaylistItems.append(currentPlaylistItem!)
            currentPlaylistItem = self.nextPlaylistItem(for: currentPlaylistItem!)
        }

        return orderedPlaylistItems
    }

    func reset(tracks: [Track]) {
        self.tracks = Set(tracks)
        self.playlistItems.removeAll()
        self.reservedPlaylistItemsKeys.removeAll()
        self.resetAddons()
        self.resetTracksTotalPlayMSeconds()
    }

    func add(traksToAdd: [Track]) {
        self.tracks = self.tracks.union(Set(traksToAdd))
    }

    func playListItem(for trackId: TrackId?) -> PlayerPlaylistItem? {
        guard let trackKey = trackId?.key else { return nil }
        return self.playlistItems[trackKey]
    }

    func contains(track: Track) -> Bool {
        return self.tracks.contains(track)
    }

    // MARK: - PlayerPlaylistItem -
    var hasPlaylisItems: Bool { return self.playlistItems.isEmpty == false }

    func contains(playlistItem: PlayerPlaylistItem) -> Bool {
        return self.playlistItems[playlistItem.key] != nil
    }

    var firstPlaylistItem: PlayerPlaylistItem? {
        guard let firstPlayListItem = self.playlistItems.filter( { return $0.value.previousKey == nil }).first else { return nil }
        return firstPlayListItem.value
    }

    var lastPlaylistItem: PlayerPlaylistItem? {
        guard let lastPlayListItem = self.playlistItems.filter( { return $0.value.nextKey == nil }).first else { return nil }
        return lastPlayListItem.value
    }

    func nextPlaylistItem(for playlistItem: PlayerPlaylistItem, cycled: Bool = false) -> PlayerPlaylistItem? {
        guard let nextPlaylistItemKey = playlistItem.nextKey else { return cycled == true ? self.firstPlaylistItem : nil }
        return self.playlistItems[nextPlaylistItemKey]
    }

    func previousPlaylistItem(for playlistItem: PlayerPlaylistItem, cycled: Bool = false) -> PlayerPlaylistItem? {
        guard let previousPlaylistItemKey = playlistItem.previousKey else { return cycled == true ? self.lastPlaylistItem : nil }
        return self.playlistItems[previousPlaylistItemKey]
    }

    func playlistItem(for trackId: TrackId?) -> PlayerPlaylistItem? {
        guard let playlistItemKey = trackId?.key else { return nil }
        return self.playlistItems[playlistItemKey]
    }

    func playlistItems(for keys: [String]) -> [PlayerPlaylistItem] {

        var filteredPlaylisyItems = [PlayerPlaylistItem]()

        for key in keys {
            guard let playlistItem = self.playlistItems[key] else { continue }
            filteredPlaylisyItems.append(playlistItem)
        }

        return filteredPlaylisyItems
    }

    // MARK: - PlayerPlaylistLinkedItem -

    func reset(with playlistItemsPaths: [String : PlayerPlaylistItemPatch?]) {

        self.reservedPlaylistItemsKeys.removeAll()
        self.playlistItems.removeAll()

        var newPlayListItems = [String : PlayerPlaylistItem]()
        for (key, value) in playlistItemsPaths {
            guard let playlistItemPatch = value, let trackId = playlistItemPatch.trackId,
                let track = self.tracks.filter({ return $0.id == trackId }).first else { continue }

            newPlayListItems[key] = PlayerPlaylistItem(with: track,
                                                       key: key,
                                                       nextKey: playlistItemPatch.nextKey?.value,
                                                       previousKey: playlistItemPatch.previousKey?.value)

        }

        if newPlayListItems.count == playlistItemsPaths.count {
            self.playlistItems = newPlayListItems
            self.reservedPlaylistItemsKeys = Set(self.playlistItems.keys)
        }

    }

    func update(with playlistItemsPaths: [String : PlayerPlaylistItemPatch?]) {

        guard playlistItemsPaths.count > 0 else { self.playlistItems.removeAll(); return }

        playlistItemsPaths.forEach { (key, playListItemPath) in
            guard let playListItemPatch = playListItemPath else { self.playlistItems.removeValue(forKey: key)
                                                                  self.reservedPlaylistItemsKeys.remove(key)
                                                                  return }
            guard let playlistItem = self.playlistItems[key] else {

                guard let trackId = playListItemPatch.trackId,
                    let track = self.tracks.filter({ return $0.id == trackId }).first else { return }

                self.playlistItems[key] = PlayerPlaylistItem(with: track,
                                                             key: key,
                                                             nextKey: playListItemPatch.nextKey?.value,
                                                             previousKey: playListItemPatch.previousKey?.value)
                self.reservedPlaylistItemsKeys.insert(key)
                return
            }

            playlistItem.apply(path: playListItemPatch)
        }
    }

    func generatePlaylistItemKey(reserve: Bool = true) -> String {

        var key: String = String(randomWithLength: 5, allowedCharacters: .alphaNumeric)

        while self.reservedPlaylistItemsKeys.contains(key) {
            key = String(randomWithLength: 5, allowedCharacters: .alphaNumeric)
        }

        if reserve { self.reservedPlaylistItemsKeys.insert(key) }

        return key
    }

    func free(reservedPlaylistItemsKeys: [String]) {
        var setToFree = Set(reservedPlaylistItemsKeys)
        setToFree.subtract(Set(self.playlistItems.keys))
        self.reservedPlaylistItemsKeys.subtract(setToFree)
    }

    func makePlaylistItem(for track: Track) -> PlayerPlaylistItem {
        let key = self.generatePlaylistItemKey()
        let newPlayListItem = PlayerPlaylistItem(with: track, key: key)
        return newPlayListItem
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

    func resetTracksTotalPlayMSeconds() {
        self.tracksTotalPlayMSeconds.removeAll()
    }

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

extension PlayerPlaylist {

    func playlistItemPatches(for tracks: [Track]) -> [PlayerPlaylistItemPatch] {
        var patches = [PlayerPlaylistItemPatch]()

        for track in tracks {
            let playListItemKey = self.generatePlaylistItemKey()
            var playlistItemPatch = PlayerPlaylistItemPatch(trackId: track.id, key: playListItemKey, nextKey: nil, previousKey: nil)

            if let lastPatchItem = patches.last {
                var previousPatchItem = lastPatchItem
                previousPatchItem.nextKey = PlayerPlaylistItemPatch.KeyType(playListItemKey)
                patches[patches.count - 1] = previousPatchItem

                playlistItemPatch.previousKey = PlayerPlaylistItemPatch.KeyType(previousPatchItem.key)
            }

            patches.append(playlistItemPatch)
        }

        return patches
    }
}

extension PlayerPlaylistItemPatch {

    static func patch(for playlistItem: PlayerPlaylistItem, nextPlaylistItemKey: String?) -> PlayerPlaylistItemPatch {

        let nextKey: KeyType = PlayerPlaylistItemPatch.KeyType(nextPlaylistItemKey)
        let previousKey: KeyType? = nextKey.isNull == true ? PlayerPlaylistItemPatch.KeyType(playlistItem.previousKey) : nil

        return PlayerPlaylistItemPatch(nextKey: nextKey, previousKey: previousKey)
    }

    static func patch(for playlistItem: PlayerPlaylistItem, previousPlaylistItemKey: String?) -> PlayerPlaylistItemPatch {

        let previousKey: KeyType = PlayerPlaylistItemPatch.KeyType(previousPlaylistItemKey)
        let nextKey: KeyType? = previousKey.isNull == true ? PlayerPlaylistItemPatch.KeyType(playlistItem.nextKey) : nil

        return PlayerPlaylistItemPatch(nextKey: nextKey, previousKey: previousKey)
    }
}
