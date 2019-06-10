//
//  PlayerRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class PlayerRouter {

    weak var owner: PlayerViewController?

    init( owner: PlayerViewController) {
        self.owner = owner
    }

}
