//
//  RootRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/23/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class RootRouter : MVVM_Router {
    
    var owner: UIViewController {
        return _owner!
    }
    
    private let interactor = PanDismissInteractor()
    
    weak private var _owner: RootRouter.T?
    init(owner: RootRouter.T) {
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
        x.viewModel = .init(router: .init(owner: x))
        owner.present(x.embededIntoNavigation(), animated: true, completion: nil)
    }
    
    func presentPlaying() {
        let x = R.storyboard.playerPlaylist.nowPlayingViewController()!
        x.viewModel = .init(router: .init(owner: x))
        owner.present(x.embededIntoNavigation(), animated: true, completion: nil)
    }
    
    func presentPlayer() {
        let x = R.storyboard.main.currentTrackViewController()!
        x.viewModel = .init(router: .init(owner: x))
        interactor.present(vc: x, on: owner)
    }
    
}


