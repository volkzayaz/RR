//
//  LyricsViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol LyricsViewModel: class {

    var lyricsText: String? { get }
    var canSwitchToKaraokeMode: Bool { get }


    func load(with delegate: LyricsViewModelDelegate)

    func switchToKaraokeMode()

}

protocol LyricsViewModelDelegate: class, ErrorPresenting {

    func refreshUI()

}
