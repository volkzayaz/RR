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

    var playerItemDurationString: String { get }

    var playerItemCurrentTimeString: String { get }

    var playerItemProgressValue: Float { get }
    var playerItemRestrictedValue: Float { get }

    var playerItemPreviewOptionsImage: UIImage? { get }

    var playerItemNameString: String { get }
    var playerItemNameAttributedString: NSAttributedString { get }

    var playerItemArtistNameString: String { get }
    var playerItemArtistNameAttributedString: NSAttributedString { get }

    var isPlayerBlocked: Bool { get }
    var isPlaying: Bool { get }

    var canForward: Bool { get }
    var canBackward: Bool { get }
    var canSetPlayerItemProgress: Bool { get }

    func load(with delegate: PlayerViewModelDelegate)

    func startObservePlayer()
    func stopObservePlayer()

    func playerItemDescriptionAttributedText(for traitCollection: UITraitCollection) -> NSAttributedString

    func play()
    func pause()
    func forward()
    func backward()
    func setPlayerItemProgress(progress: Float)
}

protocol PlayerViewModelDelegate: class {

    func refreshUI()
    func refreshProgressUI()
}
