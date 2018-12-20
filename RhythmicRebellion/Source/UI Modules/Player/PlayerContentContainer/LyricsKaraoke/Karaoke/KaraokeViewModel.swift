//
//  KaraokeViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol KaraokeViewModel: class {

    func load(with delegate: KaraokeViewModelDelegate)

    func switchToLyrics()
}

protocol KaraokeViewModelDelegate: class {

    func refreshUI()

}
