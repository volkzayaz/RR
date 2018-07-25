//
//  ListeningSettingsControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/23/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation


final class ListeningSettingsControllerViewModel: ListeningSettingsViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: ListeningSettingsViewModelDelegate?
    private(set) weak var router: ListeningSettingsRouter?
    private(set) weak var application: Application?

    private var listeningSettings: ListeningSettings = ListeningSettings.defaultSettings()
    private(set) var listeningSettingsSections: [ListeningSettingsSectionViewModel] = [ListeningSettingsSectionViewModel]()

    private(set) var isDirty: Bool = false

    // MARK: - Lifecycle -

    init(router: ListeningSettingsRouter, application: Application) {
        self.router = router
        self.application = application
    }

    private func checkDirtyState() {
        guard let fanUser = self.application?.user as? FanUser else { self.isDirty = false; return}

        let isDirty = self.listeningSettings != fanUser.listeningSettings

        if self.isDirty != isDirty {
            self.isDirty = isDirty
            self.delegate?.refreshUI()
        }
    }


    func load(with delegate: ListeningSettingsViewModelDelegate) {
        self.delegate = delegate

        guard let fanUser = self.application?.user as? FanUser else { return }

        self.listeningSettings = fanUser.listeningSettings
        self.listeningSettingsSections = self.makeListeningSettingsSections()

        self.delegate?.reloadUI()

        self.reload()
    }

    func reload() {

        self.application?.fanUser1(completion: { (fanUserResult) in
            switch fanUserResult {

            case .success(let user):
                guard let fanUser = user as? FanUser else { return }
                self.listeningSettings = fanUser.listeningSettings
                self.listeningSettingsSections = self.makeListeningSettingsSections()
                self.checkDirtyState()
                self.delegate?.reloadUI()

            case .failure(let error):
                self.delegate?.show(error: error)
            }
        })
    }

    func save() {

        self.application?.update(listeningSettings: self.listeningSettings, completion: { (updateListeningSettingsResult) in

            switch updateListeningSettingsResult {
            case .success(let listeningSettings):
                self.listeningSettings = listeningSettings
                self.listeningSettingsSections = self.makeListeningSettingsSections()
                self.checkDirtyState()
                self.delegate?.reloadUI()

            case .failure(let error):
                self.delegate?.show(error: error)
            }

        })

    }

    // MARK: - Listening Settigs Section

    func makeListeningSettingsSections() -> [ListeningSettingsSectionViewModel] {

        var listeningSettingsSections = [ListeningSettingsSectionViewModel]()

        let songComentarySectionTitle = NSLocalizedString("Song Commentary turn on/off", comment: "Song Commentary Listening Settings Title")
        let songComentarySection = ListeningSettingsSectionViewModel(title: songComentarySectionTitle,
                                                                     isOn: self.listeningSettings.isSongCommentary) { [unowned self] (songComentarySection) -> (Void) in
                                                                        self.delegate?.listeningSettingsSectionsDidBeginUpdate()
                                                                        self.songComentarySectionChanged(songComentarySection)
                                                                        self.delegate?.listeningSettingsSectionsDidEndUpdate()
                                                                        self.checkDirtyState()
        }

        if songComentarySection.isOn {
            let songCommentarySectionIsDateItem = self.songCommentarySectionIsDateItem(for: songComentarySection)
            songComentarySection.items.append(.isDate(songCommentarySectionIsDateItem))

            if songCommentarySectionIsDateItem.isOn {
                let songCommentarySectionDateItem = self.songCommentarySectionDateItem(for: songComentarySection)
                songComentarySection.items.append(.date(songCommentarySectionDateItem))
            }
        }

        listeningSettingsSections.append(songComentarySection)

        let artistsBIOSectionTitle = NSLocalizedString("Hear Artist's BIOs turn on/off", comment: "Artists BIO's Listening Settings Title")
        let artistsBIOSection = ListeningSettingsSectionViewModel(title: artistsBIOSectionTitle,
                                                                  isOn: self.listeningSettings.isHearArtistsBio) { [unowned self] (artistsBIOSection) -> (Void) in
                                                                    self.delegate?.listeningSettingsSectionsDidBeginUpdate()
                                                                    self.artistsBIOSectionChanged(artistsBIOSection)
                                                                    self.delegate?.listeningSettingsSectionsDidEndUpdate()
                                                                    self.checkDirtyState()
        }

        if artistsBIOSection.isOn {
            let artistsBIOSectionIsDateItem = self.artistsBIOSectionIsDateItem(for: artistsBIOSection)
            artistsBIOSection.items.append(.isDate(artistsBIOSectionIsDateItem))

            if artistsBIOSectionIsDateItem.isOn {
                let artistsBIOSectionDateItem = self.artistsBIOSectionDateItem(for: artistsBIOSection)
                artistsBIOSection.items.append(.date(artistsBIOSectionDateItem))
            }
        }

        listeningSettingsSections.append(artistsBIOSection)

        let explicitMaterialSectionTitle = NSLocalizedString("Explicit material", comment: "Explicit Material Listening Settings Title")
        let explicitMaterialSectionDescription = NSLocalizedString("I do not want to hear songs with lyrics that are foul or offensive.",
                                                                   comment: "Explicit Material Listening Settings Description")
        let explicitMaterialSection = ListeningSettingsSectionViewModel(title: explicitMaterialSectionTitle,
                                                                        description: explicitMaterialSectionDescription,
                                                                        isOn: self.listeningSettings.isExplicitMaterialExcluded) { (explicitMaterialSection) -> (Void) in
                                                                            self.listeningSettings.isExplicitMaterialExcluded = explicitMaterialSection.isOn
                                                                            self.checkDirtyState()
        }

        listeningSettingsSections.append(explicitMaterialSection)

        return listeningSettingsSections
    }

    // MARK: - Song Commentary Section
    func songCommentarySectionIsDateItem(for songComentarySection: ListeningSettingsSectionViewModel) -> ListeningSettingsIsDateSectionItemViewModel {

        return ListeningSettingsIsDateSectionItemViewModel(parentSectionViewModel: songComentarySection,
                                                           title: NSLocalizedString("Created After:", comment: "Created After Listening Settings Title"),
                                                           isOn: self.listeningSettings.isSongCommentaryDate) { [unowned self] (isDateSectionItem) -> (Void) in
                                                            self.delegate?.listeningSettingsSectionsDidBeginUpdate()
                                                            self.songComentarySectionIsDateItemChanged(isDateSectionItem)
                                                            self.delegate?.listeningSettingsSectionsDidEndUpdate()
                                                            self.checkDirtyState()
        }
    }

    func songCommentarySectionDateItem(for songComentarySection: ListeningSettingsSectionViewModel) -> ListeningSettingsDateSectionItemViewModel {

        return ListeningSettingsDateSectionItemViewModel(parentSectionViewModel: songComentarySection,
                                                         date: self.listeningSettings.songCommentaryDate ?? Date(), changeCallback: { [unowned self] (date) -> (Void) in
                                                            self.listeningSettings.songCommentaryDate = date
                                                            self.checkDirtyState()
        })
    }


    func songComentarySectionChanged(_ songComentarySection: ListeningSettingsSectionViewModel) {

        self.listeningSettings.isSongCommentary = songComentarySection.isOn

        if songComentarySection.isOn {
            let songCommentaryIsDateItem = self.songCommentarySectionIsDateItem(for: songComentarySection)
            let isDateSectionItem: ListeningSettingsSectionItem = .isDate(songCommentaryIsDateItem)
            songComentarySection.items.append(isDateSectionItem)

            if let isDateSectionItemIndex = songComentarySection.items.index(of: isDateSectionItem) {
                self.delegate?.listeningSettingsSection(songComentarySection, didInsertItem: isDateSectionItemIndex)
            }

            if songCommentaryIsDateItem.isOn {
                let songCommentarySectionDateItem = self.songCommentarySectionDateItem(for: songComentarySection)
                let dateSectionItem: ListeningSettingsSectionItem = .date(songCommentarySectionDateItem)
                songComentarySection.items.append(dateSectionItem)

                if let dateSectionItemIndex = songComentarySection.items.index(of: dateSectionItem) {
                    self.delegate?.listeningSettingsSection(songComentarySection, didInsertItem: dateSectionItemIndex)
                }
            }

        } else {

            if let fanUser = self.application?.user as? FanUser {
                self.listeningSettings.isSongCommentaryDate = fanUser.listeningSettings.isSongCommentaryDate
                self.listeningSettings.songCommentaryDate = fanUser.listeningSettings.songCommentaryDate
            }

            let songComentarySectionItemsCount = songComentarySection.items.count
            songComentarySection.items.removeAll()
            for itemIndex in 0..<songComentarySectionItemsCount {
                self.delegate?.listeningSettingsSection(songComentarySection, didDeleteItem: itemIndex)
            }
        }
    }

    func songComentarySectionIsDateItemChanged(_ songComentaryIsDateSectionItem: ListeningSettingsIsDateSectionItemViewModel) {

        guard let songComentarySection = songComentaryIsDateSectionItem.parentSectionViewModel else { return }

        self.listeningSettings.isSongCommentaryDate = songComentaryIsDateSectionItem.isOn

        if songComentaryIsDateSectionItem.isOn {

            let songCommentarySectionDateItem = self.songCommentarySectionDateItem(for: songComentarySection)
            let dateSectionItem: ListeningSettingsSectionItem = .date(songCommentarySectionDateItem)
            songComentarySection.items.append(dateSectionItem)

            if let dateSectionItemIndex = songComentarySection.items.index(of: dateSectionItem) {
                self.delegate?.listeningSettingsSection(songComentarySection, didInsertItem: dateSectionItemIndex)
            }
            

        } else {

            if let fanUser = self.application?.user as? FanUser {
                self.listeningSettings.songCommentaryDate = fanUser.listeningSettings.songCommentaryDate
            }

            let songComentarySectionItemsCount = songComentarySection.items.count
            songComentarySection.items.removeLast()
            self.delegate?.listeningSettingsSection(songComentarySection, didDeleteItem: songComentarySectionItemsCount - 1)
        }
    }

    // MARK: - Artists BIO Section

    func artistsBIOSectionIsDateItem(for artistsBIOSection: ListeningSettingsSectionViewModel) -> ListeningSettingsIsDateSectionItemViewModel {

        return ListeningSettingsIsDateSectionItemViewModel(parentSectionViewModel: artistsBIOSection,
                                                           title: NSLocalizedString("Created After:", comment: "Created After Listening Settings Title"),
                                                           isOn: self.listeningSettings.isHearArtistsBioDate) { [unowned self] (isDateSectionItem) -> (Void) in
                                                            self.delegate?.listeningSettingsSectionsDidBeginUpdate()
                                                            self.artistsBIOSectionIsDateItemChanged(isDateSectionItem)
                                                            self.delegate?.listeningSettingsSectionsDidEndUpdate()
                                                            self.checkDirtyState()
        }
    }

    func artistsBIOSectionDateItem(for artistsBIOSection: ListeningSettingsSectionViewModel) -> ListeningSettingsDateSectionItemViewModel {

        return ListeningSettingsDateSectionItemViewModel(parentSectionViewModel: artistsBIOSection,
                                                         date: self.listeningSettings.artistsBioDate ?? Date(), changeCallback: { [unowned self] (date) -> (Void) in
                                                            self.listeningSettings.artistsBioDate = date
                                                            self.checkDirtyState()
        })
    }

    func artistsBIOSectionChanged(_ artistsBIOSection: ListeningSettingsSectionViewModel) {
        self.listeningSettings.isHearArtistsBio = artistsBIOSection.isOn

        if artistsBIOSection.isOn {
            let artistsBIOSectionIsDateItem = self.artistsBIOSectionIsDateItem(for: artistsBIOSection)
            let isDateSectionItem: ListeningSettingsSectionItem = .isDate(artistsBIOSectionIsDateItem)
            artistsBIOSection.items.append(isDateSectionItem)

            if let isDateSectionItemIndex = artistsBIOSection.items.index(of: isDateSectionItem) {
                self.delegate?.listeningSettingsSection(artistsBIOSection, didInsertItem: isDateSectionItemIndex)
            }

            if artistsBIOSectionIsDateItem.isOn {
                let artistsBIOSectionDateItem = self.artistsBIOSectionDateItem(for: artistsBIOSection)
                let dateSectionItem: ListeningSettingsSectionItem = .date(artistsBIOSectionDateItem)
                artistsBIOSection.items.append(dateSectionItem)

                if let dateSectionItemIndex = artistsBIOSection.items.index(of: dateSectionItem) {
                    self.delegate?.listeningSettingsSection(artistsBIOSection, didInsertItem: dateSectionItemIndex)
                }
            }

        } else {

            if let fanUser = self.application?.user as? FanUser {
                self.listeningSettings.isHearArtistsBioDate = fanUser.listeningSettings.isHearArtistsBioDate
                self.listeningSettings.artistsBioDate = fanUser.listeningSettings.artistsBioDate
            }

            let artistsBIOSectionItemsCount = artistsBIOSection.items.count
            artistsBIOSection.items.removeAll()
            for itemIndex in 0..<artistsBIOSectionItemsCount {
                self.delegate?.listeningSettingsSection(artistsBIOSection, didDeleteItem: itemIndex)
            }
        }

    }

    func artistsBIOSectionIsDateItemChanged(_ artistsBIOSectionIsDateItem: ListeningSettingsIsDateSectionItemViewModel) {

        guard let artistsBIOSection = artistsBIOSectionIsDateItem.parentSectionViewModel else { return }

        self.listeningSettings.isHearArtistsBioDate = artistsBIOSectionIsDateItem.isOn

        if artistsBIOSectionIsDateItem.isOn {

            let artistsBIOSectionDateItem = self.artistsBIOSectionDateItem(for: artistsBIOSection)
            let dateSectionItem: ListeningSettingsSectionItem = .date(artistsBIOSectionDateItem)
            artistsBIOSection.items.append(dateSectionItem)

            if let dateSectionItemIndex = artistsBIOSection.items.index(of: dateSectionItem) {
                self.delegate?.listeningSettingsSection(artistsBIOSection, didInsertItem: dateSectionItemIndex)
            }

        } else {
            if let fanUser = self.application?.user as? FanUser {
                self.listeningSettings.artistsBioDate = fanUser.listeningSettings.artistsBioDate
            }

            let artistsBIOSectionItemsCount = artistsBIOSection.items.count
            artistsBIOSection.items.removeLast()
            self.delegate?.listeningSettingsSection(artistsBIOSection, didDeleteItem: artistsBIOSectionItemsCount - 1)
        }
    }
}
