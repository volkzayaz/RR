//
//  SelectableListItemViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/31/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct SelectableListItemViewModel: SelectableListItemTableViewCellViewModel {

    var id: String
    var title: String
    var isSelected: Bool

    init<T:SelectableListItem>(with selectableListItem: T, isSelected: Bool) {

        self.id = selectableListItem.identifier
        self.title = selectableListItem.title

        self.isSelected = isSelected
    }
}
