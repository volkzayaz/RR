//
//  PlayList.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

class PlayerPlaylist {    

    private(set) var tracks = Set<Track>()
    private(set) var playListItems = [String : PlayerPlaylistItem?]()
    private(set) var tracksAddons = [Int : Set<Addon>]()


    // MARK: - Tracks -
    var orderedTracks: [PlayerTrack] {
        var orderedTracks: [PlayerTrack] = [PlayerTrack]()
        var currentPlaylistItem: PlayerPlaylistItem? = self.firstPlayListItem

        while currentPlaylistItem != nil {
            if let track = self.tracks.filter({ return $0.id == currentPlaylistItem!.id }).first {
                let playerTrack = PlayerTrack(track: track, playlistItem: currentPlaylistItem!)
                orderedTracks.append(playerTrack)
            }

            guard let nextTrackKey = currentPlaylistItem?.nextTrackKey, let nextItem = self.playListItems[nextTrackKey] ?? nil else { break }
            currentPlaylistItem = nextItem
        }

        return orderedTracks
    }

    var firstTrackId: TrackId? {
        guard let firstPlayListItem = self.playListItems.filter( { return $0.value?.previousTrackKey == nil }).first,
                let firstItem = firstPlayListItem.value else { return nil }
        return TrackId(id: firstItem.id, key: firstItem.trackKey)
    }

    var lastTrackId: TrackId? {
        guard let lastPlayListItem = self.playListItems.filter( { return $0.value?.nextTrackKey == nil }).first,
                 let lastItem = lastPlayListItem.value else { return nil }
        return TrackId(id: lastItem.id, key: lastItem.trackKey)
    }

    var firstTrack: Track? {
        guard let firstTrackId = self.firstTrackId else { return nil }
        return self.track(for: firstTrackId)
    }

    func reset(tracks: [Track]) {
        self.tracks = Set(tracks)
        self.playListItems.removeAll()
        self.resetAddons()
    }

    func add(traksToAdd: [Track]) {
        self.tracks = self.tracks.union(Set(traksToAdd))
    }

    func track(for trackId: TrackId) -> Track? {
        return self.tracks.filter({ return $0.id == trackId.id }).first
    }

    func trackId(for track: Track) -> TrackId? {
        guard let playListItem = self.playListItems.filter( { return $0.value?.id == track.id }).first,
             let item = playListItem.value else { return nil }
        return TrackId(id: item.id, key: item.trackKey)
    }

    func nextTrackId(for trackId: TrackId) -> TrackId? {
        guard let playListItem = self.playListItems[trackId.key] else { return nil }

        if let playListItemNextTrackKey = playListItem?.nextTrackKey {
            if let nextPlayListItem = self.playListItems[playListItemNextTrackKey] ?? nil {
                return TrackId(id: nextPlayListItem.id, key: nextPlayListItem.trackKey)
            }
        } else if let firstTrackId = self.firstTrackId, firstTrackId.id != trackId.id {
            return firstTrackId
        }

        return nil
    }

    func previousTrackId(for trackId: TrackId) -> TrackId? {
        guard let playListItem = self.playListItems[trackId.key] else { return nil }

        if let playListItemPreviousTrackKey = playListItem?.previousTrackKey {
            if let previousPlayListItem = self.playListItems[playListItemPreviousTrackKey] ?? nil {
                return TrackId(id: previousPlayListItem.id, key: previousPlayListItem.trackKey)
            }
        } else if let lastTrackId = self.lastTrackId, lastTrackId.id != trackId.id {
            return lastTrackId
        }

        return nil
    }

    func contains(track: Track) -> Bool {
        return self.tracks.contains(track)
    }

    // MARK: - PlayerPlaylistItem -
    var firstPlayListItem: PlayerPlaylistItem? {
        guard let firstPlayListItem = self.playListItems.filter( { return $0.value?.previousTrackKey == nil }).first else { return nil }
        return firstPlayListItem.value
    }

    var lastPlayListItem: PlayerPlaylistItem? {
        guard let lastPlayListItem = self.playListItems.filter( { return $0.value?.nextTrackKey == nil }).first else { return nil }
        return lastPlayListItem.value
    }

    func reset(playListItems: [String : PlayerPlaylistItem?]) {
        self.playListItems = playListItems
    }

    func add(playListItems: [String : PlayerPlaylistItem?]) {
        self.playListItems += playListItems
    }
    
    func update(playListItems: [String : PlayerPlaylistItem?]) {
        playListItems.forEach { (key, value) in
            if (value == nil) {
                self.playListItems.removeValue(forKey: key)
            } else {
                self.playListItems[key] = value
            }
        }
    }

    func playListItem(for trackId: TrackId?) -> PlayerPlaylistItem? {
        guard let trackKey = trackId?.key else { return nil }

        return self.playListItems[trackKey] ?? nil
    }

    func generateTrackKey() -> String {

        var trackKey: String = String(randomWithLength: 5, allowedCharacters: .alphaNumeric)

        while self.playListItems[trackKey] != nil {
            trackKey = String(randomWithLength: 5, allowedCharacters: .alphaNumeric)
        }

        return trackKey
    }

    func makePlayListItem(for track: Track) -> PlayerPlaylistItem {

        let trackKey = self.generateTrackKey()

        return PlayerPlaylistItem(id: track.id, trackKey: trackKey)
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

        var addons = [Addon]()
        for addonId in addonsIds {
            guard let addon = allAddons.filter({ return $0.id == addonId }).first else { continue }
            addons.append(addon)
        }

        return addons
    }

    func addonsStates(for track: Track) -> [AddonState]? {
        return self.tracksAddons[track.id]?.map({ (addon) -> AddonState in
            return AddonState(id: addon.id, typeValue: addon.typeValue, trackId: track.id)
        })
    }
}
