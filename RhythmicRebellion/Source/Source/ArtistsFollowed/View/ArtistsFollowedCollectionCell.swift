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

class ArtistsFollowedCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    fileprivate var disposeBag = DisposeBag()
    
    var artist: Artist! {
        
        didSet {
            guard let a = artist else {
                return
            }
            
            nameLabel.text = a.name
            
//            ImageRetreiver.imageForURLWithoutProgress(url: a.urlString ?? "")
//                .drive(artistImageView.rx.image(transitionType: CATransitionType.fade.rawValue))
//                .disposed(by: disposeBag)
            
        }
        
    }
    
    var unfollow: ( () -> () )? = nil
    
    @IBAction func unfollowAction(_ sender: Any) {
        unfollow?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
