//
//  SplashViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/13/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension SplashViewModel {
    
    var finishedLoading: Driver<Void> {
        return finishedLoadingTrigger.asDriver().notNil()
    }
    
}

struct SplashViewModel : MVVM_ViewModel {
    
    fileprivate let finishedLoadingTrigger = BehaviorRelay<Void?>(value: nil)
    
    init(router: SplashRouter) {
        self.router = router
        
        ////init app state
        ////TODO: could it be that this state should live in this ViewModel?
        ////how can we unify this stroage with UnitTesting target,
        ////that requires actorStorage, but does not require UI bricks?
        let ws = WebSocketService(url: URI.webSocketService)
        let x = ActorStorage(actors: [ RRPlayer(webSocket: ws),
                                       AudioPlayer(),
                                       MediaWidget() ],
                             ws: ws)
        initActorStorage(x)
        
        Dispatcher.kickOff()
            .asObservable()
            .bind(to: finishedLoadingTrigger)
            .disposed(by: bag)
    }
    
    let router: SplashRouter
    fileprivate let bag = DisposeBag()
    
}

extension SplashViewModel {
    
    /** Reference any actions ViewModel can handle
     ** Actions should always be void funcs
     ** any result should be reflected via corresponding drivers
     
     func buttonPressed(labelValue: String) {
     
     }
     
     */
    
}
