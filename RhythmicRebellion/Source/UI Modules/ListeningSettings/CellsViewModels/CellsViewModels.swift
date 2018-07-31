//
//  CellsViewModels.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/24/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation


enum ListeningSettingsSectionItem: Equatable {
    case main(ListeningSettingsSwitchableSectionItemViewModel)
    case isDate(ListeningSettingsSwitchableSectionItemViewModel)
    case date(ListeningSettingsDateSectionItemViewModel)
}

func == (lhs: ListeningSettingsSectionItem, rhs: ListeningSettingsSectionItem) -> Bool {
    switch (lhs, rhs){
    case (.main, .main): return true
    case (.isDate, .isDate): return true
    case (.date, .date): return true
    default: return false
    }
}


class ListeningSettingsSectionViewModel {
    var items = [ListeningSettingsSectionItem]()
}

extension ListeningSettingsSectionViewModel: Equatable {
    static func == (lhs: ListeningSettingsSectionViewModel, rhs: ListeningSettingsSectionViewModel) -> Bool {
        return lhs === rhs
    }
}


class ListeningSettingsSwitchableSectionItemViewModel: SwitchableTableViewCellViewModel {

    weak var parentSectionViewModel: ListeningSettingsSectionViewModel?

    private(set) var title: String
    private(set) var description: String?
    var isOn: Bool

    var changeCallback: ((Bool) -> (Void))?

    init(parentSectionViewModel: ListeningSettingsSectionViewModel, title: String, description: String? = nil, isOn: Bool, modelChandeCallback: @escaping (ListeningSettingsSwitchableSectionItemViewModel) -> (Void)) {
        self.parentSectionViewModel = parentSectionViewModel
        self.title = title
        self.description = description
        self.isOn = isOn

        self.changeCallback = { [weak self] (isOn) in
            guard let strongSelf = self else { return }

            strongSelf.isOn = isOn
            modelChandeCallback(strongSelf)
        }
    }
}

class ListeningSettingsDateSectionItemViewModel: DatePickerTableVieCellViewModel {
    weak var parentSectionViewModel: ListeningSettingsSectionViewModel?

    var date: Date
    let changeCallback: ((Date) -> (Void))?

    init(parentSectionViewModel: ListeningSettingsSectionViewModel, date: Date, changeCallback: @escaping (Date) -> (Void)) {
        self.parentSectionViewModel = parentSectionViewModel
        self.date = date
        self.changeCallback = changeCallback
    }

}
