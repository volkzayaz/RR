//
//  TabBarControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/16/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

struct TabBarViewModel {

    private(set) weak var router: TabBarRouter?
    

    // MARK: - Lifecycle -

    init(router: TabBarRouter) {
        self.router = router
        

        let _ =
        appState.map { $0.user.isGuest }
            .distinctUntilChanged()
            .drive( onNext: { isGuest in
                
                let types: [TabType] = isGuest ?
                    [.home, .pages, .authorization] :
                    [.home, .settings, .pages, .profile, /*.myMusic, .search, .mixer*/]
                
                router.updateTabs(for: types)
                router.selectTab(for: !isGuest ? .home : .authorization)
            })
        
    }

}
