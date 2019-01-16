//
//  TrackListRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 1/9/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

struct TrackListRouter : MVVM_Router {
    
    var owner: UIViewController {
        return _owner!
    }
    
    weak private var _owner: TrackListRouter.T?
    init(owner: TrackListRouter.T) {
        self._owner = owner
    }
    
    func trackRouter(for track: Track) -> TrackRouter {
        return TrackRouter(owner: owner)
    }
    
}
