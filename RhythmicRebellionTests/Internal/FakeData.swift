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
        //    case advertisement = 0
        //    case songIntroduction = 1
        //    case songCommentary = 2
        //    case artistBIO = 3
        //    case artistAnnouncements = 4
        static let advertisement: Data = try! JsonReader.readData(withName: "addon-advertisement")
        static let songIntroduction: Data = try! JsonReader.readData(withName: "addon-songIntroduction")
        static let songCommentary: Data = try! JsonReader.readData(withName: "addon-songCommentary")
        static let artistBIO: Data = try! JsonReader.readData(withName: "addon-artistBIO")
        static let artistAnnouncements: Data = try! JsonReader.readData(withName: "addon-artistAnnouncements")
    }
    
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
