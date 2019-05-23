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
        presentEmbededIntoNavigation(x)
    }
    
    func presentLyrics() {
        let x = R.storyboard.lyricsKaraoke.lyricsKaraokeViewController()!
        x.viewModel = .init(router: .init(owner: x))
        presentEmbededIntoNavigation(x)
    }
    
    func presentPromo() {
        
    }
    
    func presentPlaying() {
        
    }
    
    func presentPlayer() {
        let x = R.storyboard.main.brandNewPlayer()!
        interactor.present(vc: x, on: owner)
    }
    
    private func presentEmbededIntoNavigation(_ x: UIViewController) {
        
        let nav = R.storyboard.main.eyeBrowNavigation()!
        nav.viewControllers = [x]

        let closeButton = UIBarButtonItem(title: "Close",
                                          style: .done,
                                          target: self, action: #selector(RootRouter.dismissController))
        closeButton.tintColor = UIColor(fromHex: 0xBFC7FF)
        
        x.navigationItem.leftBarButtonItem = closeButton
        
        owner.present(nav, animated: true, completion: nil)
    }
    
    @objc func dismissController() {
        owner.dismiss(animated: true, completion: {
        })
    }
    
    
    /**
     
     func showNextModule(with data: String) {
     
        let nextViewController = owner.storyboard.instantiate()
        let nextRouter = NextRouter(owner: nextViewController)
        let nextViewModel = NextViewModel(router: nextRuter, data: data)
        
        nextViewController.viewModel = nextViewModel
        owner.present(nextViewController)
     }
     
     */
    
}
