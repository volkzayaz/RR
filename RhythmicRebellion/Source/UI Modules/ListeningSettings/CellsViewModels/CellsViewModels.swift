//
//  CellsViewModels.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/24/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation


enum ListeningSettingsSectionItem: Equatable {
    case isDate(ListeningSettingsIsDateSectionItemViewModel)
    case date(ListeningSettingsDateSectionItemViewModel)
}

func == (lhs: ListeningSettingsSectionItem, rhs: ListeningSettingsSectionItem) -> Bool {
    switch (lhs, rhs){
    case (.isDate, .isDate): return true
    case (.date, .date): return true
    default: return false
    }
}


class ListeningSettingsSectionViewModel: SwitchableTableSectionHeaderViewModel {

    private(set) var title: String
    private(set) var description: String?

    var isOn: Bool

    var items = [ListeningSettingsSectionItem]()

    var changeCallback: ((Bool) -> (Void))?

    init(title: String, description: String? = nil, isOn: Bool, modelChandeCallback: @escaping (ListeningSettingsSectionViewModel) -> (Void)) {
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

extension ListeningSettingsSectionViewModel: Equatable {
    static func == (lhs: ListeningSettingsSectionViewModel, rhs: ListeningSettingsSectionViewModel) -> Bool {
        return lhs === rhs
    }
}


class ListeningSettingsIsDateSectionItemViewModel: SwitchableTableViewCellViewModel {

    weak var parentSectionViewModel: ListeningSettingsSectionViewModel?

    private(set) var title: String
    var isOn: Bool

    var changeCallback: ((Bool) -> (Void))?

    init(parentSectionViewModel: ListeningSettingsSectionViewModel, title: String, isOn: Bool, modelChandeCallback: @escaping (ListeningSettingsIsDateSectionItemViewModel) -> (Void)) {
        self.parentSectionViewModel = parentSectionViewModel
        self.title = title
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
