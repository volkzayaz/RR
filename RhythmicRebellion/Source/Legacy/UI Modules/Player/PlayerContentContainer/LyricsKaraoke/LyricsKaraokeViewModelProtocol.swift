//
//  LyricsKaraokeContainerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import RxSwift
import RxCocoa

protocol LyricsKaraokeViewModelProtocol: class {

    var lyricsStateError: BehaviorRelay<Error?> { get }

    func load(with delegate: LyricsKaraokeViewModelDelegate)

}

protocol LyricsKaraokeViewModelDelegate: class, ErrorPresenting {

    func refreshUI()

}
