//
//  Observable.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation


struct WatcherReference<T>: Equatable {
    private(set) weak var internalReference: AnyObject?
    init(_ observer: T) { internalReference = observer as AnyObject }
    var reference: T? { return internalReference as? T }
    static func ==(lhs: WatcherReference, rhs: WatcherReference) -> Bool {
        return lhs.internalReference === rhs.internalReference
    }

    static func ==(lhs: WatcherReference, rhs: AnyObject) -> Bool {
        return lhs.internalReference === rhs
    }

}

class WatchersContainer<T> {

    private var watchers = [WatcherReference<T>]()

    func add(_ observer: T) {
        let observerReference = WatcherReference<T>(observer)
        if self.watchers.index(of: observerReference) == nil {
            self.watchers.append(observerReference)
        }
    }

    func remove(_ observer: T) {
        if let index = self.watchers.firstIndex(where: { $0 == observer as AnyObject }) {
            self.watchers.remove(at: index)
        }
    }

    func invoke(_ invocation: @escaping (T) -> ()) {

        watchers.forEach { (observerReferences) in
            guard let observer = observerReferences.reference else { return }
            invocation(observer)
        }
    }
}

protocol Watchable {

    associatedtype WatchType: Any

    var watchersContainer: WatchersContainer<WatchType> { get }

    func addWatcher(_ observer: WatchType)
    func removeWatcher(_ observer: WatchType)
}

extension Watchable {

    func addWatcher(_ observer: WatchType) {
        self.watchersContainer.add(observer)
    }

    func removeWatcher(_ observer: WatchType) {
        self.watchersContainer.remove(observer)
    }
}
