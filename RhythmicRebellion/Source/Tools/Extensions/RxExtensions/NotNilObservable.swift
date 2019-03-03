//
//  Var.swift
//     
//
//  Created by Vlad Soroka on 10/5/16.
//  Copyright © 2016    All rights reserved.
//

import RxSwift
import RxCocoa

protocol OptionalEquivalent {
    associatedtype WrappedValueType
    func unwrap() -> WrappedValueType
    func isNotNil() -> Bool
}

extension Optional: OptionalEquivalent {
    typealias WrappedValueType = Wrapped
    
    func unwrap() -> Wrapped {
        return self.unsafelyUnwrapped
    }
    
    func isNotNil() -> Bool {
        
        switch self {
        case .none:
            return false
        case .some(_):
            return true
        }
        
    }
}

extension ObservableType where E: OptionalEquivalent {
    
    func notNil() -> Observable<E.WrappedValueType> {
        
        return self.asObservable()
            .filter { $0.isNotNil() }
            .map { $0.unwrap() }
        
    }
    
}

extension SharedSequenceConvertibleType where SharingStrategy == DriverSharingStrategy, E: OptionalEquivalent {
    
    func notNil() -> Driver<E.WrappedValueType> {
        
        return self
            .filter { $0.isNotNil() }
            .map { $0.unwrap() }
            
    }
    
}

extension BehaviorSubject {
    
    var unsafeValue: Element {
        return try! value()
    }
    
}

extension BehaviorRelay {
    
    var _value: Element {
        get {
            return self.value
        }
        set {
            self.accept(newValue)
        }
    }
    
}
