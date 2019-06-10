//
//  ArtistsFollowedCollectionCell.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/19/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class ArtistsFollowedCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    var artist: Artist! {
        
        didSet {
            guard let a = artist else {
                return
            }
            
            nameLabel.text = a.name
            
        }
        
    }
    
    var unfollow: ( () -> () )? = nil
    
    @IBAction func unfollowAction(_ sender: Any) {
        unfollow?()
    }
    
}
