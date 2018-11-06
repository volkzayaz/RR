//
//  ApplicationSettings.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/6/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Defaults {

    private enum DefaultsKeys: String {
        case lastSignedUserEmail = "User.lastSignedEmail"
    }

    static var lastSignedUserEmail: String? {
        set {
            guard let newValue = newValue else { UserDefaults.standard.removeObject(forKey: DefaultsKeys.lastSignedUserEmail.rawValue); return }
            UserDefaults.standard.set(newValue, forKey: DefaultsKeys.lastSignedUserEmail.rawValue)
        }

        get { return UserDefaults.standard.value(forKey: DefaultsKeys.lastSignedUserEmail.rawValue) as? String }
    }
}
