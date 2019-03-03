//
//  SettingsStore.swift
//  Smartreading
//
//  Created by Vlad Soroka on 8/27/18.
//  Copyright © 2018 Vlad Soroka. All rights reserved.
//

import Foundation

enum SettingsStore {}
extension SettingsStore {
    
    static var lastSignedUserEmail: Setting<String?> = Setting(key: "User.lastSignedEmail",
                                                               initialValue: nil)
    
}
