//
//  PlayerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerViewModel: class {

    var playerItemDuration: Float? { get }
    var playerItemDurationString: String { get }

    var playerItemCurrentTime: Float? { get }
    var playerItemCurrentTimeString: String { get }

    var playerItemProgress: Float { get }

    var isPlaying: Bool { get }

    func load(with delegate: PlayerViewModelDelegate)

    func startObservePlayer()
    func stopObservePlayer()

    func playerItemDescriptionAttributedText(for traitCollection: UITraitCollection) -> NSAttributedString

    func play()
    func pause()
    func forward()
    func backward()


}

protocol PlayerViewModelDelegate: class {

    func refreshUI()
    func refreshProgressUI()
}
