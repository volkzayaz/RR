//
//  Observable.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation


struct ObserverReference<T>: Equatable {
    private(set) weak var internalReference: AnyObject?
    init(_ observer: T) { internalReference = observer as AnyObject }
    var reference: T? { return internalReference as? T }
    static func ==(lhs: ObserverReference, rhs: ObserverReference) -> Bool {
        return lhs.internalReference === rhs.internalReference
    }

    static func ==(lhs: ObserverReference, rhs: AnyObject) -> Bool {
        return lhs.internalReference === rhs
    }

}

class ObserversContainer<T> {

    private var observers = [ObserverReference<T>]()

    func add(_ observer: T) {
        let observerReference = ObserverReference<T>(observer)
        if self.observers.index(of: observerReference) == nil {
            self.observers.append(observerReference)
        }
    }

    func remove(_ observer: T) {
        if let index = self.observers.firstIndex(where: { $0 == observer as AnyObject }) {
            self.observers.remove(at: index)
        }
    }

    func invoke(_ invocation: @escaping (T) -> ()) {

        observers.forEach { (observerReferences) in
            guard let observer = observerReferences.reference else { return }
            invocation(observer)
        }
    }
}

protocol Observable {

    associatedtype ObserverType: Any

    var observersContainer: ObserversContainer<ObserverType> { get }

    func addObserver(_ observer: ObserverType)
    func removeObserver(_ observer: ObserverType)
}

extension Observable {

    func addObserver(_ observer: ObserverType) {
        self.observersContainer.add(observer)
    }

    func removeObserver(_ observer: ObserverType) {
        self.observersContainer.remove(observer)
    }
}
