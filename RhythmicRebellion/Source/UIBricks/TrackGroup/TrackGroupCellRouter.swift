//
//  TrackGroupCellRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/8/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

struct TrackGroupCellRouter : MVVM_Router {
    
    var owner: UIViewController {
        return _owner!
    }
    
    weak private var _owner: TrackGroupCellRouter.T?
    init(owner: TrackGroupCellRouter.T) {
        self._owner = owner
    }
    
    func present(actions: AlertActionsViewModel<ActionViewModel>) {
        
        let actionSheet = UIAlertController.make(from: actions)
        
//        actionSheet.popoverPresentationController?.sourceView = sourceView
//        actionSheet.popoverPresentationController?.sourceRect = sourceRect
        
        owner.present(actionSheet, animated: true, completion: nil)
        
    }
    
    func presentPlaylistCreation(for tracks: [Track]) {
        
        let x = R.storyboard.main.addToPlaylistViewController()!
        let router = AddToPlaylistRouter()
        router.start(controller: x, tracks: tracks)
        
        owner.present(UINavigationController(rootViewController: x),
                      animated: true, completion: nil)
    }
    
}
