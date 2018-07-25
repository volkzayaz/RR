//
//  PlayList.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

class PlayList {

    private(set) var tracks = [Track]()
    private(set) var playListItems = [String : PlayListItem]()
    private(set) var tracksAddons = [Int : [Addon]]()

    var firstTrackId: TrackId? {
        guard let firstPlayListItem = self.playListItems.filter( { return $0.value.previousTrackKey == nil }).first else { return nil }
        return TrackId(id: firstPlayListItem.value.id, key: firstPlayListItem.value.trackKey)
    }

    var lastTrackId: TrackId? {
        guard let lastPlayListItem = self.playListItems.filter( { return $0.value.nextTrackKey == nil }).first else { return nil }
        return TrackId(id: lastPlayListItem.value.id, key: lastPlayListItem.value.trackKey)
    }

    var firstTrack: Track? {
        guard let firstTrackId = self.firstTrackId else { return nil }
        return self.track(for: firstTrackId)
    }

    func reset(tracks: [Track]) {
        self.tracks = tracks
        self.playListItems.removeAll()
        self.resetAddons()
    }

    func reset(playListItems: [String : PlayListItem]) {
        self.playListItems = playListItems
    }

    func resetAddons() {
        self.tracksAddons.removeAll()
    }

    func add(traks: [Track]) {
        self.tracks.append(contentsOf: tracks)
    }

    func add(playListItems: [String : PlayListItem]) {
        self.playListItems += playListItems
    }

    func add(tracksAddons: [Int : [Addon]]) {
        self.tracksAddons += tracksAddons
    }

    func track(for trackId: TrackId) -> Track? {
        return self.tracks.filter({ return $0.id == trackId.id }).first
    }

    func trackId(for track: Track) -> TrackId? {
        guard let playListItem = self.playListItems.filter( { return $0.value.id == track.id }).first else { return nil }
        return TrackId(id: playListItem.value.id, key: playListItem.value.trackKey)
    }

    func nextTrackId(for trackId: TrackId) -> TrackId? {
        guard let playListItem = self.playListItems[trackId.key] else { return nil }

        if let playListItemNextTrackKey = playListItem.nextTrackKey {
            if let nextPlayListItem = self.playListItems[playListItemNextTrackKey] {
                return TrackId(id: nextPlayListItem.id, key: nextPlayListItem.trackKey)
            }
        } else if let firstTrackId = self.firstTrackId, firstTrackId.id != trackId.id {
            return firstTrackId
        }

        return nil
    }

    func previousTrackId(for trackId: TrackId) -> TrackId? {
        guard let playListItem = self.playListItems[trackId.key] else { return nil }

        if let playListItemPreviousTrackKey = playListItem.previousTrackKey {
            if let previousPlayListItem = self.playListItems[playListItemPreviousTrackKey] {
                return TrackId(id: previousPlayListItem.id, key: previousPlayListItem.trackKey)
            }
        } else if let lastTrackId = self.lastTrackId, lastTrackId.id != trackId.id {
            return lastTrackId
        }

        return nil
    }

    func addons(for track: Track) -> [Addon]? {

        return self.tracksAddons[track.id]
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
