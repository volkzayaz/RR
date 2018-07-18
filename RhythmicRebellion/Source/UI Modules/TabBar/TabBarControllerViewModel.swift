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

    // MARK: - Private properties -

    private(set) weak var delegate: TabBarViewModelDelegate?
    private(set) weak var router: TabBarRouter?
    private(set) weak var application: Application?

    // MARK: - Lifecycle -

    init(router: TabBarRouter, application: Application) {
        self.router = router
        self.application = application
    }

    deinit {
        self.application?.removeObserver(self)
    }

    func tabTypes(for user: User?) -> [TabType] {
        guard let user = user, user.isGuest == false else { return [.home, .pages, .authorization] }

        return [.home, .settings, .pages, .profile, /*.myMusic, .search, .mixer*/]
    }

    func load(with delegate: TabBarViewModelDelegate) {
        self.delegate = delegate

        self.application?.addObserver(self)

        self.router?.updateTabs(for: self.tabTypes(for: self.application?.user))

    }
}

extension TabBarControllerViewModel: ApplicationObserver {

    func application(_ application: Application, didChangeUser user: User?) {
        self.router?.updateTabs(for: self.tabTypes(for: user))
    }
}

