//
//  DaPlaylist.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 2/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

typealias TrackOrderHash = String

struct OrderedTrack: Equatable {
    
    let track: Track
    let orderHash: TrackOrderHash
    
    init(track: Track, hash: String? = nil) {
        self.track = track
        orderHash = hash ?? String(randomWithLength: 5, allowedCharacters: .alphaNumeric)
    }
    
    func reduxView(previousTrack: OrderedTrack? = nil,
                   nextTrack    : OrderedTrack? = nil) -> [DaPlaylist.ViewKey: Any?] {
        
        var res: [DaPlaylist.ViewKey: Any?] = [ .id       : track.id,
                                                .hash     : orderHash,
                                                .previous : nil,
                                                .next     : nil ]
        
        if let x = previousTrack {
            res[.previous] = x.orderHash
        }
        
        if let x = nextTrack {
            res[.next] = x.orderHash
        }
        
        return res
    }
    
    static func ==(lhs: OrderedTrack, rhs: OrderedTrack) -> Bool {
        return lhs.orderHash == rhs.orderHash
    }
    
}


struct DaPlaylist {
    
    /*HashTable representation of two DoublyLinkedList
     {
     "5tuvm": {
            id: 11,                     //Int     *points to underline track*
            trackKey: "5tuvm",          //String  *Duplicates key in the hashTable*
            nextTrackKey: "sfz3g"       //String? *points to next node*
            previousTrackKey: "65f08"   //String? *points to previous node*
        },
     ....
     */
    var reduxView: ReduxView = [:]
    
    ///Dictionary of trackID and corresponding Track
    ///All tracks that are present in reduxView
    ///Are always a subset of this Dictionary
    ///Mutated by ApplyReduxViewPatch
    var trackDump: [Int: Track] = [:]
    
    ///Dictionary of trackID and corresponding preview time
    ///that has been already played by user
    ///Mutated by RRPlayer.didReceivePreviewTimes
    var previewTime: [Int: UInt64] = [:]
    
    var orderedTracks: [OrderedTrack] {
        
        guard reduxView.count > 0 else { return [] }
        
        var res: [OrderedTrack] = []
        
        ///starting from the head
        let head = reduxView.first(where: { (_, value) in
            return value[.previous]! == nil
        })!
        
        var pointer: TrackOrderHash? = head.key
        
        while let p = pointer {
        
            let node = reduxView[p]!
                
            let trackID =   node[.id]!   as! Int
            let orderHash = node[.hash]! as! String
            
            res.append( OrderedTrack(track: trackDump[trackID]!,
                                     hash: orderHash) )
            
            pointer = node[.next]! as? String
            
        }
        
        return res
    }
    
    subscript(index: TrackOrderHash) -> OrderedTrack? {
        get {
            guard let item = reduxView[index],
                  let trackID = item[.id]! as? Int,
                  let track = trackDump[trackID] else {
                    return nil
            }
            
            return OrderedTrack(track: track, hash: index)
        }
    }
    
    func next(after: TrackOrderHash) -> OrderedTrack? {
        var it = orderedTracks.makeIterator()
        
        while let x = it.next() {
            if x.orderHash == after { break }
        }
        
        return it.next()
    }
    
    func previous(before: TrackOrderHash) -> OrderedTrack? {
        var it = orderedTracks.reversed().makeIterator()
        
        while let x = it.next() {
            if x.orderHash == before { break }
        }
        
        return it.next()
    }
    
    enum ViewKey: String {
        case id
        case hash = "trackKey"
        case next = "nextTrackKey"
        case previous = "previousTrackKey"
    }
    typealias ReduxView         = [ TrackOrderHash: [ViewKey: Any?]  ]
    typealias NullableReduxView = [ TrackOrderHash: [ViewKey: Any?]? ]
    
    fileprivate mutating func clear() {
        reduxView = [:]
    }
    
    fileprivate mutating func apply(patch: DaPlayerState.ReduxViewPatch) {
        
        if patch.shouldFlush { clear() }
        
        patch.patch.forEach { (orderHash, maybeValue) in
            
            guard let value = maybeValue else {
                
                ///Deleted node
                reduxView.removeValue(forKey: orderHash)
                
                return
            }
            
            if var x = reduxView[orderHash] {
               
                ///updated node
                ///ViewKey.next, ViewKey.prev are updated
               
                value.forEach { (key, value) in
                    ///be aware, that we might get either value, or absence of it
                    let maybeUpdate: Any? = value
                    
                    x[key] = maybeUpdate
                }
                
                reduxView[orderHash] = x
                
                return
            }
            
            ///create node
            reduxView[orderHash] = maybeValue
            
        }
        
    }
    
    fileprivate func insertPatch(tracks: [Track], after: OrderedTrack?) -> NullableReduxView {
        
        guard tracks.count > 0 else { return [:] }
        
        let leftHash           = after?.orderHash
        let rightHash: String? = {
            guard let x = leftHash else {
                return orderedTracks.first?.orderHash
            }
            
            return reduxView[x]?[.next]! as? String
        }()

        var res: NullableReduxView = [:]

        
        var it = tracks.makeIterator()
        var from = OrderedTrack(track: it.next()!)
        
        res[from.orderHash] = from.reduxView()
        if let x = leftHash {
            res[x] = [.next : from.orderHash]
            res[from.orderHash]??[.previous] = x
        }
        
        while let x = it.next() {
            
            let to = OrderedTrack(track: x)
            
            res[from.orderHash]??[.next] = to.orderHash
            res[to  .orderHash]          = to.reduxView(previousTrack: from)
            
            from = to
        }
        
        if let x = rightHash {
            res[x] = [.previous : from.orderHash]
            res[from.orderHash]??[.next] = x
        }
        
        return res

    }
    
    fileprivate func deletePatch(track: OrderedTrack) -> NullableReduxView {
        
        guard let nodeToDelete = reduxView[track.orderHash],
              let prevHash = nodeToDelete[.previous] as? String?,
              let nextHash = nodeToDelete[.next]     as? String? else {
            fatalError("Internal inconsistency. Can not delete track \(track.track) since it is not present in reduxView \(reduxView)")
        }
        
        var res: NullableReduxView = [track.orderHash: nil]
        if let x = prevHash {
            res[x] = [ .next : nextHash ]
        }
        if let x = nextHash {
            res[x] = [ .previous : prevHash ]
        }
        
        return res
    }
    
}

extension DaPlaylist: CustomStringConvertible {
    
    var description: String {
        var res = "Stored Tracks: \([trackDump.map { "{id = \($0.key), \($0.value.name)}; " }]) "
        res.append("Tracks(ids) order:\n")
        
        orderedTracks.forEach {
            res.append("\($0.track.id) -> ")
        }
        
        res.append("end")
        return res
    }
    
}

extension DaPlaylist: Equatable {
    static func == (lhs: DaPlaylist, rhs: DaPlaylist) -> Bool {
        
        guard lhs.previewTime == rhs.previewTime,
              lhs.trackDump == rhs.trackDump,
              lhs.reduxView.count == rhs.reduxView.count else { return false }
        
        for (key, value) in lhs.reduxView {
            
            guard let x = rhs.reduxView[key] else {
                return false
            }
            
            if (
            (x[.hash]     as? String) == (value[.hash]     as? String) &&
            (x[.id]       as? Int)    == (value[.id]       as? Int) &&
            (x[.next]     as? String) == (value[.next]     as? String) &&
            (x[.previous] as? String) == (value[.previous] as? String) ) {
                continue
            }
            
            return false
        }
        
        return true
    }
}

extension DaPlayerState.ReduxViewPatch: Equatable {
    
    static func == (lhs: DaPlayerState.ReduxViewPatch, rhs: DaPlayerState.ReduxViewPatch) -> Bool {
        
        guard lhs.patch.count == rhs.patch.count else { return false }
        
        for (key, value) in lhs.patch {
            
            guard let x = rhs.patch[key] else {
                return false
            }
            
            if (
                (x?[.hash]     as? String) == (value?[.hash]     as? String) &&
                (x?[.id]       as? Int)    == (value?[.id]       as? Int) &&
                (x?[.next]     as? String) == (value?[.next]     as? String) &&
                (x?[.previous] as? String) == (value?[.previous] as? String) ) {
                continue
            }
            
            return false
        }
        
        return true
    }
    
}

import RxSwift

struct ApplyReduxViewPatch: ActionCreator {
    
    let viewPatch: DaPlayerState.ReduxViewPatch
    let assosiatedTracks: [Track]
    init (viewPatch: DaPlayerState.ReduxViewPatch, assosiatedTracks: [Track] = []) {
        self.viewPatch = viewPatch
        self.assosiatedTracks = assosiatedTracks
    }
    
    func perform(initialState: AppState) -> Observable<AppState> {

        ///getting state
        var state = initialState
        var tracks = state.player.tracks
        
        ///applying transform
        tracks.apply(patch: viewPatch)
        let allTrackIds = Set(tracks.reduxView.map { $0.value[.id]! as! Int })
        
        ///fetching underlying tracks if needed
        var tracksDiff = allTrackIds.subtracting(tracks.trackDump.keys)
        
        ///avoiding roundtrip to server
        assosiatedTracks.forEach { x in
            guard !tracksDiff.contains(x.id) else { return }
            tracks.trackDump[x.id] = x
            tracksDiff.remove(x.id)
        }
        
        ////setting state
        state.player.tracks = tracks
        state.player.lastPatch = viewPatch
        if viewPatch.shouldFlush {
            state.player.currentItem = nil
        }
        
        guard tracksDiff.count > 0 else {
            return .just(state)
        }
        
        return DataLayer.get.webSocketService
            .fetchTracks(trackIds: Array(tracksDiff))
            .map { receivedTracks -> AppState in
                
                receivedTracks.forEach { tracks.trackDump[$0.id] = $0 }
                
                state.player.tracks = tracks
                
                return state
            }
        
    }
    
}

struct InsertTracks: ActionCreator {
    
    let tracks: [Track]
    let afterTrack: OrderedTrack?
    let isOwnChange: Bool
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        ///initial state
        let tracks = initialState.player.tracks
        
        ///getting state transform
        let patch = tracks.insertPatch(tracks: self.tracks, after: afterTrack)
        
        ///mapping state transform
        let reduxPatch = DaPlayerState.ReduxViewPatch(isOwn: isOwnChange, shouldFlush: false, patch: patch)
        
        ///applying state transform
        return ApplyReduxViewPatch(viewPatch: reduxPatch,
                                   assosiatedTracks: self.tracks).perform(initialState: initialState)
        
    }
}

struct DeleteTrack: ActionCreator {
    
    let track: OrderedTrack
    let isOwnChange: Bool
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        ///initial state
        let tracks = initialState.player.tracks
        
        ///getting state transform
        let patch = tracks.deletePatch(track: track)
        
        ///mapping state transform
        let reduxPatch = DaPlayerState.ReduxViewPatch(isOwn: isOwnChange, shouldFlush: false, patch: patch)
        
        ///applying state transform
        return ApplyReduxViewPatch(viewPatch: reduxPatch,
                                   assosiatedTracks: []).perform(initialState: initialState)
        
    }
}

struct ClearTracks: ActionCreator {
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        let reduxPatch = DaPlayerState.ReduxViewPatch(isOwn: true, shouldFlush: true, patch: [:])
        
        return ApplyReduxViewPatch(viewPatch: reduxPatch,
                                   assosiatedTracks: []).perform(initialState: initialState)
    }
    
}

struct ReplaceTracks: ActionCreator {

    let with: [Track]
    let isOwnChange: Bool
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        ///initial state
        var tracks = initialState.player.tracks
        
        ///getting state transform
        tracks.clear() ///otherwise patch will try to insert tracks in the beggining
        let patch = tracks.insertPatch(tracks: with, after: nil)
        
        ///mapping state transform
        let reduxPatch = DaPlayerState.ReduxViewPatch(isOwn: isOwnChange, shouldFlush: true, patch: patch)
        
        ///applying state transform
        return ApplyReduxViewPatch(viewPatch: reduxPatch,
                                   assosiatedTracks: with).perform(initialState: initialState)
        
    }
    
}

