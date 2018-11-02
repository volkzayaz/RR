//
//  Dictionary+Extension.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/10/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

func + <K,V>(left: Dictionary<K,V>, right: Dictionary<K,V>) -> Dictionary<K,V> {
    var map = Dictionary<K,V>()
    for (k, v) in left { map[k] = v }
    for (k, v) in right { map[k] = v }
    return map
}

func += <K,V>(left: inout Dictionary<K,V>, right: Dictionary<K,V>) {
    for (k, v) in right { left[k] = v }
}


extension Sequence {
    public func toDictionary<K: Hashable, V>(_ selector: (Iterator.Element) throws -> (K, V)?) rethrows -> [K: V] {
        var dict = [K: V]()
        for element in self {
            if let (key, value) = try selector(element) {
                dict[key] = value
            }
        }
        return dict
    }
}
