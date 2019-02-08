//
//  Double+Extension.swift
//  Smartreading
//
//  Created by Vlad Soroka on 2/8/19.
//  Copyright © 2019 Vlad Soroka. All rights reserved.
//

import Foundation

extension Double {
    
    var audioDurationString: String {
        
        guard self.isNormal else {
            return ""
        }
        
        let duration = Int(self)
        let minutes = duration / 60
        let seconds = duration % 60
        
        return NSString(format: "%d:%02d", minutes, seconds) as String
    }
    
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
