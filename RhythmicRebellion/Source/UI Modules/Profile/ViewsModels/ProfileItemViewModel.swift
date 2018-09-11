//
//  ProfileItemViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/11/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct ProfileItemViewModel: ProfileItemTableViewCellViewModel {

    var id: String { return String(profileItem.rawValue) }

    var title: String { return profileItem.name }

    let profileItem: ProfileItem

    init(with profileItem: ProfileItem) {
        self.profileItem = profileItem
    }
}
