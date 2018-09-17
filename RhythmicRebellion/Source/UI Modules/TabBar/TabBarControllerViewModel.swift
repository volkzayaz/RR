//
//  TabBarControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/16/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class TabBarControllerViewModel: TabBarViewModel {

    enum UserType {
        case guest
        case authorized
    }

    // MARK: - Private properties -

    private(set) weak var delegate: TabBarViewModelDelegate?
    private(set) weak var router: TabBarRouter?
    private(set) weak var application: Application?

    private var userType: UserType

    // MARK: - Lifecycle -

    init(router: TabBarRouter, application: Application) {
        self.router = router
        self.application = application

        self.userType = application.user?.isGuest ?? true ? .guest : .authorized
    }

    deinit {
        self.application?.removeObserver(self)
    }

    func tabTypes(for userType: UserType) -> [TabType] {
        
        guard userType == .authorized else { return [.home, .pages, .authorization] }

        return [.home, .settings, .pages, .profile, /*.myMusic, .search, .mixer*/]
    }

    func load(with delegate: TabBarViewModelDelegate) {
        self.delegate = delegate

        self.userType = self.application?.user?.isGuest ?? true ? .guest : .authorized
        self.router?.updateTabs(for: self.tabTypes(for: self.userType))


        self.application?.addObserver(self)
    }
}

extension TabBarControllerViewModel: ApplicationObserver {

    func application(_ application: Application, didChange user: User) {

        let userType: UserType = user.isGuest ? .guest : .authorized

        self.router?.updateTabs(for: self.tabTypes(for: userType))

        guard self.userType != userType else { return }

        self.userType = userType

        self.router?.selectTab(for: self.userType == .authorized ? .home : .authorization)
    }
}

