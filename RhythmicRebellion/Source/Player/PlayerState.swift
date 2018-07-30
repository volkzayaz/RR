//
//  PlayerState.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/13/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct PlayerState: OptionSet {

    let rawValue: Int

    static let initialized                              = PlayerState(rawValue: 1 << 0)
    static let audioSessionInterrupted                  = PlayerState(rawValue: 1 << 1)
    static let playingBeforeAudioSessionInterruption    = PlayerState(rawValue: 1 << 2)
    static let playing                                  = PlayerState(rawValue: 1 << 3)
    static let waitingAddons                            = PlayerState(rawValue: 1 << 4)
    static let blocked                                  = PlayerState(rawValue: 1 << 5)

    var initialized: Bool {
        set { if newValue == true { self.insert(.initialized) } else { self.remove(.initialized) } }
        get { return self.contains(.initialized) }
    }

    var audioSessionInterrupted: Bool {
        set { if newValue == true { self.insert(.audioSessionInterrupted) } else { self.remove(.audioSessionInterrupted) } }
        get { return self.contains(.audioSessionInterrupted) }
    }

    var playingBeforeAudioSessionInterruption: Bool {
        set { if newValue == true { self.insert(.playingBeforeAudioSessionInterruption) } else { self.remove(.playingBeforeAudioSessionInterruption) } }
        get { return self.contains(.playingBeforeAudioSessionInterruption) }
    }


    var playing: Bool {
        set { if newValue == true { self.insert(.playing) } else { self.remove(.playing) } }
        get { return self.contains(.playing) }
    }

    var blocked: Bool {
        set { if newValue == true { self.insert(.blocked) } else { self.remove(.blocked) } }
        get { return self.contains(.blocked) }
    }

    var waitingAddons: Bool {
        set { if newValue == true { self.insert(.waitingAddons) } else { self.remove(.waitingAddons) } }
        get { return self.contains(.waitingAddons) }
    }

}
