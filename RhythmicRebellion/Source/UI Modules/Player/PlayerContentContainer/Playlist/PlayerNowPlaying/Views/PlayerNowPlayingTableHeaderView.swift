//
//  PlayerNowPlayingTableHeaderView.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/7/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit


class PlayerNowPlayingTableHeaderView: UIView {

    typealias ActionCallback = (Actions) -> Void

    enum Actions {
        case clear
        case repeatOne
    }

    var actionCallback: ActionCallback?

    func setup(actionCallback:  @escaping ActionCallback) {
        self.actionCallback = actionCallback
    }

    // MARK: - Actions -

    @IBAction func onClear() {
        self.actionCallback?(.clear)
    }
}
