//
//  BaseFlowLayout.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/19/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import UIKit

class BaseFlowLayout: UICollectionViewFlowLayout {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        itemSize = CGSize(width: 177.5, height: 160.5)
    }
    
    func configureFor(bounds: CGRect) {
        
        let offset = minimumInteritemSpacing + sectionInset.left + sectionInset.right
        let viewWidth = min(bounds.width, bounds.height)
        let lineWidth = offset + 2 * itemSize.width
        if lineWidth > viewWidth {
            let itemWidth = (viewWidth - offset) / 2
            itemSize = CGSize(width: floor(itemWidth),
                              height: (itemWidth / 1.10625).rounded())
        }
        
    }
    
}
