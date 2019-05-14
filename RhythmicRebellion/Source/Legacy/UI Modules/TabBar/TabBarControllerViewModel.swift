//
//  TabBarControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/16/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import RxCocoa

extension TabBarViewModel {
    
    var tabs: Driver<[TabType]> {
        
        return appState.map { $0.user.isGuest }
            .distinctUntilChanged()
            .map({ (isGuest) in
                
                let types: [TabType] = isGuest ?
                    [.home, .pages, .authorization] :
                    [.home, .settings, .pages, .profile, /*.myMusic, .search, .mixer*/]
                
                return types
            })
        
    }
    
    var openedTab: Driver<TabType> {
        return  appState.map { !$0.user.isGuest }
            .distinctUntilChanged()
            .scan(nil, accumulator: { y, x in return y == nil ? true : x })
            .map({ (shouldOpenHome) in
                return shouldOpenHome! ? .home : .authorization
            })
    }
    
}

struct TabBarViewModel {

    let router: TabBarRouter
    
    init(router: TabBarRouter) {
        self.router = router
        
    }

}
