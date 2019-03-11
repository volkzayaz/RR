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
        case env = "User.env"
    }

    static var lastSignedUserEmail: String? {
        set {
            guard let newValue = newValue else { UserDefaults.standard.removeObject(forKey: DefaultsKeys.lastSignedUserEmail.rawValue); return }
            UserDefaults.standard.set(newValue, forKey: DefaultsKeys.lastSignedUserEmail.rawValue)
        }

        get { return UserDefaults.standard.value(forKey: DefaultsKeys.lastSignedUserEmail.rawValue) as? String }
    }
    
    
    static var Env: String {
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultsKeys.env.rawValue)
            UserDefaults.standard.synchronize()
        }
        
        get { return UserDefaults.standard.value(forKey: DefaultsKeys.env.rawValue) as? String ?? "rr-3287" }
    }
    
}
