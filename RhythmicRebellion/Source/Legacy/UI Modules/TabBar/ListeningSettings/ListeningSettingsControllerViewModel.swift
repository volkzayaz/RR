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
    private(set) var isSaving: Bool = false

    // MARK: - Lifecycle -

    init(router: ListeningSettingsRouter, application: Application) {
        self.router = router
        self.application = application
    }

    private func checkDirtyState() {
        
        let isDirty = self.listeningSettings != self.application?.user?.profile?.listeningSettings

        if self.isDirty != isDirty {
            self.isDirty = isDirty
            self.delegate?.refreshUI()
        }
    }


    func load(with delegate: ListeningSettingsViewModelDelegate) {
        self.delegate = delegate

        guard let profile = self.application?.user?.profile else { return }

        self.application?.addWatcher(self)

        self.listeningSettings = profile.listeningSettings
        self.listeningSettingsSections = self.makeListeningSettingsSections()

        self.delegate?.reloadUI()

        self.reload()
    }

    func reload() {

        let _ =
        UserRequest.login.rx.baseResponse(type: User.self)
            .subscribe(onSuccess: { [weak self] user in
                
                self?.listeningSettings = user.profile?.listeningSettings ?? .defaultSettings()
                self?.listeningSettingsSections = self!.makeListeningSettingsSections()
                self?.checkDirtyState()
                self?.delegate?.reloadUI()
                
            }, onError: { [weak self] error in
                self?.delegate?.show(error: error, completion: { [weak self] in self?.delegate?.reloadUI() })
            })
        
    }

    func save() {

        self.isSaving = true

        let _ =
        UserRequest.updateListeningSettings(ListeningSettingsPayload(with: listeningSettings))
            .rx.baseResponse(type: User.self)
            .subscribe(onSuccess: { [weak self] user in
                
                self?.isSaving = false
                
                self?.listeningSettingsSections = self!.makeListeningSettingsSections()
                self?.checkDirtyState()
                self?.delegate?.reloadUI()
                
                }, onError: { [weak self] error in
                    
                    self?.isSaving = false
                    
                    self?.delegate?.show(error: error, completion: { [weak self] in self?.delegate?.reloadUI() })
            })

    }

    // MARK: - Listening Settigs Section -

    func makeListeningSettingsSections() -> [ListeningSettingsSectionViewModel] {

        var listeningSettingsSections = [ListeningSettingsSectionViewModel]()

        let songCommentarySection = ListeningSettingsSectionViewModel()

        let songComentarySectionMainItemTitle = NSLocalizedString("Song Commentary turn on/off", comment: "Song Commentary Listening Settings Title")
        let songComentarySectionMainItem = ListeningSettingsSwitchableSectionItemViewModel(parentSectionViewModel: songCommentarySection,
                                                                                           title: songComentarySectionMainItemTitle,
                                                                                           isOn: self.listeningSettings.isSongCommentary) { [unowned self] (songComentarySectionMainItem) -> (Void) in
                                                                                                    self.delegate?.listeningSettingsSectionsDidBeginUpdate()
                                                                                                    self.songComentarySectionMainItemChanged(songComentarySectionMainItem)
                                                                                                    self.delegate?.listeningSettingsSectionsDidEndUpdate()
                                                                                                    self.checkDirtyState()
                                                                                            }
        songCommentarySection.items.append(.main(songComentarySectionMainItem))

        if songComentarySectionMainItem.isOn {
            let songCommentarySectionIsDateItem = self.songCommentarySectionIsDateItem(for: songCommentarySection)
            songCommentarySection.items.append(.isDate(songCommentarySectionIsDateItem))

            if songCommentarySectionIsDateItem.isOn {
                let songCommentarySectionDateItem = self.songCommentarySectionDateItem(for: songCommentarySection)
                songCommentarySection.items.append(.date(songCommentarySectionDateItem))
            }
        }

        listeningSettingsSections.append(songCommentarySection)

        let artistsBIOSection = ListeningSettingsSectionViewModel()

        let artistsBIOSectionMainItemTitle = NSLocalizedString("Hear Artist's BIOs turn on/off", comment: "Artists BIO's Listening Settings Title")
        let artistsBIOSectionMainItem = ListeningSettingsSwitchableSectionItemViewModel(parentSectionViewModel: artistsBIOSection,
                                                                                        title: artistsBIOSectionMainItemTitle,
                                                                                        isOn: self.listeningSettings.isHearArtistsBio) { [unowned self] (artistsBIOSectionMainItem) -> (Void) in
                                                                                                self.delegate?.listeningSettingsSectionsDidBeginUpdate()
                                                                                                self.artistsBIOSectionMainItemChanged(artistsBIOSectionMainItem)
                                                                                                self.delegate?.listeningSettingsSectionsDidEndUpdate()
                                                                                                self.checkDirtyState()
                                                                                        }
        artistsBIOSection.items.append(.main(artistsBIOSectionMainItem))

        if artistsBIOSectionMainItem.isOn {
            let artistsBIOSectionIsDateItem = self.artistsBIOSectionIsDateItem(for: artistsBIOSection)
            artistsBIOSection.items.append(.isDate(artistsBIOSectionIsDateItem))

            if artistsBIOSectionIsDateItem.isOn {
                let artistsBIOSectionDateItem = self.artistsBIOSectionDateItem(for: artistsBIOSection)
                artistsBIOSection.items.append(.date(artistsBIOSectionDateItem))
            }
        }

        listeningSettingsSections.append(artistsBIOSection)


        let explicitMaterialSection = ListeningSettingsSectionViewModel()

        let explicitMaterialSectionMainItemTitle = NSLocalizedString("Explicit material", comment: "Explicit Material Listening Settings Title")
        let explicitMaterialSectionMainItemDescription = NSLocalizedString("I do not want to hear songs with lyrics that are foul or offensive.",
                                                                           comment: "Explicit Material Listening Settings Description")
        let explicitMaterialSectionMainItem = ListeningSettingsSwitchableSectionItemViewModel(parentSectionViewModel: explicitMaterialSection,
                                                                                              title: explicitMaterialSectionMainItemTitle,
                                                                                              description: explicitMaterialSectionMainItemDescription,
                                                                                              isOn: self.listeningSettings.isExplicitMaterialExcluded) { [unowned self] (explicitMaterialSectionMainItem) -> (Void) in
                                                                                                    self.listeningSettings.isExplicitMaterialExcluded = explicitMaterialSectionMainItem.isOn
                                                                                                    self.checkDirtyState()
                                                                                                }
        explicitMaterialSection.items.append(.main(explicitMaterialSectionMainItem))

        listeningSettingsSections.append(explicitMaterialSection)

        return listeningSettingsSections
    }

    // MARK: - Song Commentary Section -
    func songCommentarySectionIsDateItem(for songComentarySection: ListeningSettingsSectionViewModel) -> ListeningSettingsSwitchableSectionItemViewModel {

        return ListeningSettingsSwitchableSectionItemViewModel(parentSectionViewModel: songComentarySection,
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


    func songComentarySectionMainItemChanged(_ songComentarySectionMainItem: ListeningSettingsSwitchableSectionItemViewModel) {
        guard let songComentarySection = songComentarySectionMainItem.parentSectionViewModel else { return }

        self.listeningSettings.isSongCommentary = songComentarySectionMainItem.isOn

        if songComentarySectionMainItem.isOn {
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

            if let profile = self.application?.user?.profile {
                self.listeningSettings.isSongCommentaryDate = profile.listeningSettings.isSongCommentaryDate
                self.listeningSettings.songCommentaryDate = profile.listeningSettings.songCommentaryDate
            }

            let songComentarySectionItemsCount = songComentarySection.items.count
            songComentarySection.items.removeSubrange(1..<songComentarySectionItemsCount)
            for itemIndex in 1..<songComentarySectionItemsCount {
                self.delegate?.listeningSettingsSection(songComentarySection, didDeleteItem: itemIndex)
            }
        }
    }

    func songComentarySectionIsDateItemChanged(_ songComentaryIsDateSectionItem: ListeningSettingsSwitchableSectionItemViewModel) {
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

            if let profile = self.application?.user?.profile {
                self.listeningSettings.songCommentaryDate = profile.listeningSettings.songCommentaryDate
            }

            let songComentarySectionItemsCount = songComentarySection.items.count
            songComentarySection.items.removeLast()
            self.delegate?.listeningSettingsSection(songComentarySection, didDeleteItem: songComentarySectionItemsCount - 1)
        }
    }

    // MARK: - Artists BIO Section -

    func artistsBIOSectionIsDateItem(for artistsBIOSection: ListeningSettingsSectionViewModel) -> ListeningSettingsSwitchableSectionItemViewModel {

        return ListeningSettingsSwitchableSectionItemViewModel(parentSectionViewModel: artistsBIOSection,
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

    func artistsBIOSectionMainItemChanged(_ artistsBIOSectionMainItem: ListeningSettingsSwitchableSectionItemViewModel) {
        guard let artistsBIOSection = artistsBIOSectionMainItem.parentSectionViewModel else { return }

        self.listeningSettings.isHearArtistsBio = artistsBIOSectionMainItem.isOn

        if artistsBIOSectionMainItem.isOn {
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

            if let profile = self.application?.user?.profile {
                self.listeningSettings.isHearArtistsBioDate =  profile.listeningSettings.isHearArtistsBioDate
                self.listeningSettings.artistsBioDate = profile.listeningSettings.artistsBioDate
            }

            let artistsBIOSectionItemsCount = artistsBIOSection.items.count
            artistsBIOSection.items.removeSubrange(1..<artistsBIOSectionItemsCount)
            for itemIndex in 1..<artistsBIOSectionItemsCount {
                self.delegate?.listeningSettingsSection(artistsBIOSection, didDeleteItem: itemIndex)
            }
        }

    }

    func artistsBIOSectionIsDateItemChanged(_ artistsBIOSectionIsDateItem: ListeningSettingsSwitchableSectionItemViewModel) {
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
            
            self.listeningSettings.artistsBioDate = self.application?.user?.profile?.listeningSettings.artistsBioDate
            
            let artistsBIOSectionItemsCount = artistsBIOSection.items.count
            artistsBIOSection.items.removeLast()
            self.delegate?.listeningSettingsSection(artistsBIOSection, didDeleteItem: artistsBIOSectionItemsCount - 1)
        }
    }
}

extension ListeningSettingsControllerViewModel: ApplicationWatcher {

    func application(_ application: Application, didChangeUserProfile listeningSettings: ListeningSettings) {

        guard self.isSaving == false else { return }

        self.listeningSettings = listeningSettings
        self.listeningSettingsSections = self.makeListeningSettingsSections()
        self.checkDirtyState()
        self.delegate?.reloadUI()
    }
}
