//
//  LyricsRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class LyricsRouter {

    weak var sourceController: UIViewController?
    
    init(owner: UIViewController) {
        self.sourceController = owner
    }

}
