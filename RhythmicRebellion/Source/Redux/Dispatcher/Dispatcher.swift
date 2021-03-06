//
//  Dispatcher.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 2/8/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import RxSwift
import RxCocoa

enum Dispatcher {
    
    static func dispatch(action: Action) {
        dispatch(action: ActionCreatorWrapper(action: action) )
    }
    
    static func dispatch(action: ActionCreator) {
        
        actions.onNext(action)
        
    }
    
    static let actions = BehaviorSubject<ActionCreator?>(value: nil)
    
    static func kickOff() -> Maybe<Void> {
        beginSerialExecution()
        
        return initAppState()
    }
    
    static func beginSerialExecution() {
        ///Serial execution
        let _ =
        actions.notNil().concatMap { actionCreator -> Observable<AppState> in
            
            let forceCompleteTrigger = Observable.just( () ).delay(10, scheduler: MainScheduler.instance)
                .do(onNext: {
                    fatalErrorInDebug("Action \(actionCreator) exceeded 10 seconds quota to update appState. State that was mutated: \(String(describing: state.value)) ")
                })
            
            return Observable.deferred { () -> Observable<AppState> in
                print("Dispatching \(actionCreator.description)")
                return actionCreator.perform(initialState: state.value!)
                    .map { state in
                        
                        ////signing action with it's signature
                        var x = state
                        x.player.lastChangeSignatureHash = actionCreator.signature
                        return x
                }
                }
                .takeUntil(forceCompleteTrigger)
                .catchError({ (error) -> Observable<AppState> in
                    fatalErrorInDebug("Action \(actionCreator.description) has errored which is unsupported. Error \(error)")
                    return .just(state.value!)
                })
            
            }
            .filter { $0 != state.value }
            .bind(to: state)
    }
}
