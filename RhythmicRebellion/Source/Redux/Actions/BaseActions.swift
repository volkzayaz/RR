//
//  Base.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/18/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

///Syncrhonous action
protocol Action {
    
    func perform( initialState: AppState ) -> AppState
    
    var signature: Signature { get }
    
}

extension Action {
    
    var signature: Signature {
        return WebSocketService.ownSignatureHash
    }
    
}

///Asyncrhonous action
protocol ActionCreator: CustomStringConvertible {
    
    ///Make sure your Observable eventually completes.
    ///Non completable observables will block the whole execution Queue
    func perform( initialState: AppState ) -> Observable<AppState>
    
    var signature: Signature { get }
    
}

extension ActionCreator {
    
    var description: String {
        return "\(type(of: self))"
    }
    
    var signature: Signature {
        return WebSocketService.ownSignatureHash
    }
    
}

////Wrapper for syncronous action
struct ActionCreatorWrapper: ActionCreator {
    let action: Action
    
    func perform(initialState: AppState) -> Observable<AppState> {
        return .just( action.perform(initialState: initialState) )
    }
    
    var description: String {
        return ":\(type(of: action))"
    }
    
    var signature: Signature {
        return action.signature
    }
    
}

///Wrapper for actions with alien signatures
struct AlienSignatureWrapper: ActionCreator {
    
    let action: ActionCreator
    
    init(action: ActionCreator) {
        self.action = action
    }
    
    init(action: Action) {
        self.action = ActionCreatorWrapper(action: action)
    }
    
    func perform(initialState: AppState) -> Observable<AppState> {
        return action.perform(initialState: initialState)
    }
    
    var description: String {
        return action.description
    }
    
    var signature: Signature {
        return WebSocketService.alienSignatureHash
    }
    
}
