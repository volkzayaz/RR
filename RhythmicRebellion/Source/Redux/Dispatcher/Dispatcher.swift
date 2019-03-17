//
//  Dispatcher.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 2/8/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import RxSwift
import RxCocoa

///Syncrhonous action
protocol Action {
    
    func perform( initialState: AppState ) -> AppState
    
}

///Asyncrhonous action
protocol ActionCreator: CustomStringConvertible {
    
    ///Make sure your Observable eventually completes.
    ///Non completable observables will block the whole execution Queue
    func perform( initialState: AppState ) -> Observable<AppState>
    
}

enum Dispatcher {
    
    static func dispatch(action: Action) {
        dispatch(action: ActionCreatorWrapper(action: action) )
    }
    
    static func dispatch(action: ActionCreator) {
        
        print("Enqueing \(action.description)")
        
        actions.onNext(action)
        
    }
    
    
    static let actions = BehaviorSubject<ActionCreator?>(value: nil)
    
    static func kickOff() {
        
        ///Serial execution
        let _ =
        actions.notNil().concatMap { actionCreator -> Observable<AppState> in
            
            let forceCompleteTrigger = Observable.just( () ).delay(10, scheduler: MainScheduler.instance)
                .do(onNext: {
                    fatalErrorInDebug("Action \(actionCreator) exceeded 10 seconds quota to update appState. State that was mutated: \(state.value) ")
                })
            
                return Observable.deferred { () -> Observable<AppState> in
                    print("Dispatching \(actionCreator.description)")
                    return actionCreator.perform(initialState: state.value)
                }
                .takeUntil(forceCompleteTrigger)
            
            }
            .filter { $0 != state.value }
            .bind(to: state)
        
    }
    
}

extension ActionCreator {
    func prepare(initialState: AppState) -> AppState {
        return initialState
    }
    
    var description: String {
        return "\(type(of: self))"
    }
}

struct ActionCreatorWrapper: ActionCreator {
    let action: Action
    
    func perform(initialState: AppState) -> Observable<AppState> {
        return .just( action.perform(initialState: initialState) )
    }
    
    var description: String {
        return ":\(type(of: action))"
    }
    
}
