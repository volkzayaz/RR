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
    
    func present(actions: [RRSheet.Action]) {
        owner.show(viewModels: actions)
    }
    
    func presentPlaylistCreation(for tracks: [Track], inclusionClosure: @escaping InclusionClosure) {
        
        let r = R.storyboard.main.addToPlaylistContainer()!
        let x = R.storyboard.main.addToPlaylistViewController()!
        
        x.viewModel = .init(router: .init(owner: x),
                            attachable: tracks,
                            inclusionClosure: inclusionClosure)
        
        r.viewControllers = [x]
        
        owner.present(r, animated: true, completion: nil)
        
    }
    
}
