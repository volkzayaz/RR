//
//  LyricsKaraokeContainerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol LyricsKaraokeViewModelProtocol: class {

    func load(with delegate: LyricsKaraokeViewModelDelegate)

}

protocol LyricsKaraokeViewModelDelegate: class, ErrorPresenting {

    func refreshUI()

}
