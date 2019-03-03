//
//  ListeningSettingsViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/23/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit


protocol ListeningSettingsViewModel: class {

    var isDirty: Bool { get }
    
    var listeningSettingsSections: [ListeningSettingsSectionViewModel] { get }

    func load(with delegate: ListeningSettingsViewModelDelegate)
    func reload()
    func save()
}

protocol ListeningSettingsViewModelDelegate: class, ErrorPresenting {

    func refreshUI()
    func reloadUI()

    func listeningSettingsSectionsDidBeginUpdate()
    func listeningSettingsSection(_ listeningSettingsSection: ListeningSettingsSectionViewModel, didInsertItem at: Int)
    func listeningSettingsSection(_ listeningSettingsSection: ListeningSettingsSectionViewModel, didDeleteItem at: Int)
    func listeningSettingsSectionsDidEndUpdate()
}
