//
//  tracks.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/9/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RhythmicRebellion

public struct FakeData {
    static let addon: Data = try! JsonReader.readData(withName: "audio-add-ons-for-tracks")
    static let artist: Data = try! JsonReader.readData(withName: "artist")
}

let t1 = Track.fake(id: 1)
let t2 = Track.fake(id: 2)
let t3 = Track.fake(id: 3)
let t4 = Track.fake(id: 3)
let t5 = Track.fake(id: 4)
let t6 = Track.fake(id: 5)
let t7 = Track.fake(id: 7)
let t8 = Track.fake(id: 8)
let t9 = Track.fake(id: 9)
let t10 = Track.fake(id: 10)

struct Tracks {    
    static var all: [Track] {
        return [t1, t2, t3, t4, t5, t6, t7, t8, t9, t10]
    }
}
