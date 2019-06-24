//
//  AddToPlaylistRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

struct AddToPlaylistRouter {

    private(set) weak var owner: UIViewController?

    init(owner: UIViewController) {
        self.owner = owner
    }
    
    func dismiss() {
        owner?.dismiss(animated: true, completion: nil)
    }
}
