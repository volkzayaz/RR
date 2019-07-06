//
//  LinkedPlaylist.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 2/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct LinkedPlaylist {
    
    /*HashTable representation of DoublyLinkedList
     {
     "5tuvm": {
            id: 11,                     //Int     *points to underline track*
            trackKey: "5tuvm",          //String  *Duplicates key in the hashTable*
            nextTrackKey: "sfz3g"       //String? *points to next node*
            previousTrackKey: "65f08"   //String? *points to previous node*
        },
     ....
     */
    private(set) var reduxView: ReduxView = [:]
    
    ///Dictionary of trackID and corresponding Track
    ///All tracks that are present in reduxView
    ///Are always a subset of this Dictionary
    ///Mutated by ApplyReduxViewPatch
    var trackDump: [Int: Track] = [:]
    
    var shouldShuffle: Bool = false { didSet { updateReflection() } }
    var shouldRepeat: Bool = false
    
    ///Holds references of all tracks in ReduxView
    ///Purpose: provide order of playback for tracks
    ///Respects |shuffle| setting
    ///Use trackFollowing(after:) for accessing exact neighbour of given track
    ///regardless of order settings
    private var orderReflection: [TrackOrderHash] = []
    
    ///Dictionary of trackID and corresponding preview time
    ///that has been already played by user
    ///Mutated by RRPlayer.didReceivePreviewTimes
    var previewTime: [Int: UInt64] = [:]
    
    private var orderedTrackHashes: [TrackOrderHash] {
        guard reduxView.count > 0 else { return [] }
        
        var res: [TrackOrderHash] = []
        
        ///starting from the head
        let head = reduxView.first(where: { (_, value) in
            return value[.previous]! == nil
        })!
        
        var pointer: TrackOrderHash? = head.key
        while let p = pointer {
            
            let node = reduxView[p]!
            
            let orderHash = node[.hash]! as! String
            
            res.append( orderHash )
            
            pointer = node[.next]! as? String
            
        }
        
        return res
    }
    
    var orderedTracks: [OrderedTrack] {
        return orderedTrackHashes.compactMap { self[$0] }
    }
    
    var count: Int {
        return reduxView.count
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
    
    ///Track that is next in linked playlist
    ///Ignores all repeat and shuffle logics
    func trackFollowing(after: TrackOrderHash) -> OrderedTrack? {
        
        guard let key = reduxView[after]?[.next] as? TrackOrderHash else {
            return nil
        }
        
        return self[key]
    }
    
    func next(after: TrackOrderHash) -> OrderedTrack? {
        if shouldRepeat {
            return self[after]
        }
        
        var it = orderReflection.makeIterator()
        
        while let x = it.next() {
            if x == after { break }
        }
        
        guard let hash = it.next() else { ///after is last track in the reflection
            return nil
        }
        
        return self[hash]
    }
    
    func previous(before: TrackOrderHash) -> OrderedTrack? {
        var it = orderReflection.reversed().makeIterator()
        
        while let x = it.next() {
            if x == before { break }
        }
        
        guard let hash = it.next() else { ///before is last track in the reflection
            return nil
        }
        
        return self[hash]
    }
    
    enum ViewKey: String {
        case id
        case hash = "trackKey"
        case next = "nextTrackKey"
        case previous = "previousTrackKey"
    }
    
    typealias ReduxView         = [ TrackOrderHash: [ViewKey: Any?]  ]
    typealias NullableReduxView = [ TrackOrderHash: [ViewKey: Any?]? ]
    
    mutating func clear() {
        reduxView = [:]
        updateReflection()
    }
    
    mutating func apply(patch: PlayerState.ReduxViewPatch) {
        
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
        
        updateReflection()
    }
    
    private mutating func updateReflection() {
        orderReflection = shouldShuffle ? reduxView.keys.shuffled() : orderedTrackHashes
    }
    
    func insertPatch(tracks: [Track], after: OrderedTrack?) -> NullableReduxView {
        
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
    
    func deletePatch(track: OrderedTrack) -> NullableReduxView {
        
        guard let nodeToDelete = reduxView   [track.orderHash],
              let prevHash     = nodeToDelete[.previous] as? String?,
              let nextHash     = nodeToDelete[.next]     as? String? else {
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

extension LinkedPlaylist: Equatable {
    
    static func == (lhs: LinkedPlaylist, rhs: LinkedPlaylist) -> Bool {
        
        guard lhs.previewTime == rhs.previewTime,
              lhs.trackDump == rhs.trackDump,
              lhs.shouldShuffle == rhs.shouldShuffle,
              lhs.shouldRepeat == rhs.shouldRepeat,
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

extension PlayerState.ReduxViewPatch: Equatable {
    
    static func == (lhs: PlayerState.ReduxViewPatch, rhs: PlayerState.ReduxViewPatch) -> Bool {
        
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
