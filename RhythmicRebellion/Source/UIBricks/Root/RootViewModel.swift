//
//  RootViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/23/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension RootViewModel {
    
    /** Reference binding drivers that are going to be used in the corresponding view
    
    var text: Driver<String> {
        return privateTextVar.asDriver().notNil()
    }
 
     */
    
}

struct RootViewModel : MVVM_ViewModel {
    
    /** Reference dependent viewModels, managers, stores, tracking variables...
     
     fileprivate let privateDependency = Dependency()
     
     fileprivate let privateTextVar = BehaviourRelay<String?>(nil)
     
     */
    
    init(router: RootRouter) {
        self.router = router
        
        /**
         
         Proceed with initialization here
         
         */
        
        /////progress indicator
        
        indicator.asDriver()
            .drive(onNext: { [weak h = router.owner] (loading) in
                h?.changedAnimationStatusTo(status: loading)
            })
            .disposed(by: bag)
    }
    
    let router: RootRouter
    fileprivate let indicator: ViewIndicator = ViewIndicator()
    fileprivate let bag = DisposeBag()
    
}

extension RootViewModel {
    
    func presentVideo() {
        router.presentVideo()
    }
    
    func presentLyrics() {
        router.presentLyrics()
    }
    
    func presentPromo() {
        router.presentPromo()
    }
    
    func presentPlaying() {
        router.presentPlaying()
    }
    
    func presentPlayer() {
        router.presentPlayer()
    }
    
}
