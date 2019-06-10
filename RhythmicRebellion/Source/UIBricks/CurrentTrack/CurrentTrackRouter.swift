//
//  CurrentTrackRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/5/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class CurrentTrackRouter : MVVM_Router {
    
    var owner: UIViewController {
        return _owner!
    }
    
    weak private var _owner: CurrentTrackRouter.T?
    init(owner: CurrentTrackRouter.T) {
        self._owner = owner
    }
    
    func presentVideo() {
        let x = R.storyboard.main.videoViewController()!
        x.viewModel = VideoViewModel(router: .init(owner: x))
        owner.present(x.embededIntoNavigation(), animated: true, completion: nil)
    }
    
    func presentLyrics() {
        let x = R.storyboard.lyricsKaraoke.lyricsKaraokeViewController()!
        x.viewModel = .init(router: .init(owner: x))
        owner.present(x.embededIntoNavigation(), animated: true, completion: nil)
    }
    
    func presentPromo() {
        let x = R.storyboard.main.promoViewController()!
        x.viewModel = .init(router: .init(owner: x), delegate: x)
        owner.present(x.embededIntoNavigation(), animated: true, completion: nil)
    }
    
    func presentPlaying() {
        let x = R.storyboard.playerPlaylist.nowPlayingViewController()!
        x.viewModel = .init(router: .init(owner: x))
        owner.present(x.embededIntoNavigation(), animated: true, completion: nil)
    }

}
