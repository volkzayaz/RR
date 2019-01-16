//
//  NWise.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 1/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

extension ObservableType {
    public func nwise(_ n: Int) -> Observable<[E]> {
        return self
            .scan([]) { acc, item in Array((acc + [item]).suffix(n)) }
            .filter { $0.count == n }
    }
    
    public func pairwise() -> Observable<(E, E)> {
        return self.nwise(2)
            .map { ($0[0], $0[1]) }
    }
    
    public func ternate() -> Observable<(E, E, E)> {
        return self.nwise(3)
            .map { ($0[0], $0[1], $0[2]) }
    }
}
