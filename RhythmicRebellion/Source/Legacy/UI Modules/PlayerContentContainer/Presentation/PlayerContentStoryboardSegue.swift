//
//  TabBarModalSegue.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/26/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class PlayerContentStoryboardSegue: UIStoryboardSegue {

    override func perform() {
        self.source.present(destination, animated: true, completion: nil)
    }
}
