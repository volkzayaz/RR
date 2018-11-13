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

    var playerItemPreviewOptionViewModel: TrackPreviewOptionViewModel? { get }

    var playerItemNameString: String { get }
    var playerItemNameAttributedString: NSAttributedString { get }

    var playerItemArtistNameString: String { get }
    var playerItemArtistNameAttributedString: NSAttributedString { get }

    var playerItemTrackLikeState: Track.LikeStates { get }
    var canChangePlayerItemTrackLikeState: Bool { get }

    var isPlayerBlocked: Bool { get }

    var canChangePlayState: Bool { get }
    var isPlaying: Bool { get }

    var canForward: Bool { get }
    var canBackward: Bool { get }
    var canSetPlayerItemProgress: Bool { get }

    var canFollowArtist: Bool { get }
    var isArtistFollowed: Bool { get }

    func load(with delegate: PlayerViewModelDelegate)

    func playerItemDescriptionAttributedText(for traitCollection: UITraitCollection) -> NSAttributedString

    func play()
    func pause()
    func forward()
    func backward()
    func toggleLike()
    func toggleDislike()
    func setPlayerItemProgress(progress: Float)
    func toggleArtistFollowing()

    func canNavigate(to playerNavigationItemType: PlayerNavigationItemType) -> Bool
    func navigate(to playerNavigationItemType: PlayerNavigationItemType)
}

protocol PlayerViewModelDelegate: class, ErrorPresenting {

    func refreshUI()
    func refreshProgressUI()
}
