//
//  PromoRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

class PromoRouter : MVVM_Router {
    
    var owner: UIViewController {
        return _owner!
    }
    
    weak private var _owner: CurrentTrackRouter.T?
    init(owner: CurrentTrackRouter.T) {
        self._owner = owner
    }
    
}
