//
//  TrackCells.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class TrackTableViewCell: UITableViewCell, CellIdentifiable {
    static let identifier = R.reuseIdentifier.trackTableViewCellIdentifier.identifier
    
    var trackView: TrackView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        trackView = R.nib.trackView.instantiate(withOwner: self).first as? TrackView
        
        contentView.addSubview(trackView)
    }
    
    override func updateConstraints() {
        
        trackView.snp.remakeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
        
        super.updateConstraints()
    }
    
}

class TrackCollectionViewCell: UICollectionViewCell {
    
    var trackView: TrackView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        trackView = R.nib.trackView.instantiate(withOwner: self).first as? TrackView
        
        contentView.addSubview(trackView)
    }
    
    override func updateConstraints() {
        
        trackView.snp.remakeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
        
        super.updateConstraints()
    }
    
}
