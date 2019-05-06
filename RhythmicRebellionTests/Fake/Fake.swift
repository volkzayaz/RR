//
//  Fake.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 2/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
@testable import RhythmicRebellion

protocol Fakeble {
    static func fake() -> Self
}

extension Fakeble {
    
    static func fakeString(components: Int = 2) -> String {
        
        let strings = "Sed utro perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae abes illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt Neque porro quisquam est qui dolorem ipsum quia dolor sit amet consectetur adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur Quis autem vel eum iure reprehenderit qui indf eaeq voluptate velit esse quam nihil molestiae consequatur vel illum qui dolorem eum fugiat quo voluptas nulla pariatur"
            .replacingOccurrences(of: ",", with: "")
            .components(separatedBy: " ")
        
        var result: [String] = []
        
        for _ in 0 ..< components {
            let dice1 = arc4random_uniform(UInt32(strings.count));
            result.append(strings[Int(dice1)])
        }
        
        return result.joined(separator: " ")
    }
    
    static func fakeNumber(bound: UInt32) -> Int {
        return Int(arc4random_uniform(bound))
        
    }
    
    static func fakeDouble(min: Double, max: Double) -> Double {
        
        let normilizer = Double(fakeNumber(bound: 100000)) / Double(100000)
        return (max - min) * normilizer
        
    }
    
    static func fakeDate() -> Date {
        
        return Date(timeIntervalSince1970: TimeInterval(fakeNumber(bound: UInt32(Date().timeIntervalSince1970))))
        
    }
    
    static func fakeBool() -> Bool {
        
        let x = arc4random_uniform(2)
        
        return x == 0
    }
    
    static func fakeValue<T>(from: [T]) -> T {
        
        let count = from.count
        
        guard count > 0 else {
            fatalError("Can't pick item from empty array")
        }
        
        return from [ fakeNumber(bound: UInt32(count)) ]
    }

}