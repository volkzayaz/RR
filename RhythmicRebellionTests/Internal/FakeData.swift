//
//  tracks.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/9/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RhythmicRebellion

struct FakeData {
    
    struct Addon {
        static let advertisement: Data = try! JsonReader.readData(withName: "addon-advertisement")
        static let songIntroduction: Data = try! JsonReader.readData(withName: "addon-songIntroduction")
        static let songCommentary: Data = try! JsonReader.readData(withName: "addon-songCommentary")
        static let artistBIO: Data = try! JsonReader.readData(withName: "addon-artistBIO")
        static let artistAnnouncements: Data = try! JsonReader.readData(withName: "addon-artistAnnouncements")
    }
    
    struct Artists {
        static let artist: Data = try! JsonReader.readData(withName: "artist")
        static let following: Data = try! JsonReader.readData(withName: "artists-following")
    }
    
    struct Lyrics {
        static let `default`: Data = try! JsonReader.readData(withName: "lyrics")
    }
    
    struct PlayLists {
        static let all: Data = try! JsonReader.readData(withName: "playlists")
    }
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
let trackCommingSoon = Track.fake(id: 10, audioFile: nil)

struct Tracks {    
    static var all: [Track] {
        return [t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, trackCommingSoon]
    }
}
