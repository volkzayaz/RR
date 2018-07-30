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

    func load(with delegate: LyricsViewModelDelegate)

}

protocol LyricsViewModelDelegate: class {

    func refreshUI()

}
