//
//  AudioPlayer.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 2/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct AudioPlayer {
    
    struct Props {
        
        //let name
        
    }
    
}

typealias TrackOrderHash = String

struct OrderedTrack {
    
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
            
            res.append( OrderedTrack(track: Track.fake(id: trackID),
                                     hash: orderHash) )
            
            pointer = node[.next]! as? String
            
        }
        
        return res
    }
    
    
    enum ViewKey: String {
        case id
        case hash = "trackKey"
        case next = "nextTrackKey"
        case previous = "previousTrackKey"
    }
    typealias ReduxView         = [ TrackOrderHash: [ViewKey: Any?]  ]
    typealias NullableReduxView = [ TrackOrderHash: [ViewKey: Any?]? ]
    
    mutating func apply(patch: NullableReduxView) {
        
        patch.forEach { (orderHash, maybeValue) in
            
            guard let value = maybeValue else {
                
                ///Deleted node
                reduxView.removeValue(forKey: orderHash)
                
                return
            }
            
            if value.count == 1,
               let first = maybeValue?.first,
               var x = reduxView[orderHash] {
               
                ///updated node
                ///either ViewKey.next or ViewKey.prev is updated
                
                ///be aware, that we might get either value, or absence of it
                let maybeUpdate: Any? = first.value
                
                x[first.key] = maybeUpdate
                reduxView[orderHash] = x
                
                return
            }
            
            ///create node
            reduxView[orderHash] = maybeValue
            
        }
        
    }
    
    mutating func insert(tracks: [Track], after: OrderedTrack?) -> NullableReduxView {
        
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
        
        apply(patch: res)
        
        return res

    }
    
    mutating func delete(track: OrderedTrack) -> NullableReduxView {
        
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
        
        apply(patch: res)
        
        return res
    }
    
}
