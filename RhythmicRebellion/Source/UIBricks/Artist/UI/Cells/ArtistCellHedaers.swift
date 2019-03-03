//
//  ArtistCellHedaers.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/29/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class ArtistCoverHeader: UICollectionReusableView {
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var sectionNameLabel: UILabel!
    
    var coverURL: String? {
        didSet {
            
            ImageRetreiver.imageForURLWithoutProgress(url: coverURL ?? "")
                .map { [weak v = coverImageView] x -> UIImage? in
                    if let x = x {
                        v?.contentMode = .scaleAspectFill
                        return x
                    }
                    
                    v?.contentMode = .center
                    return R.image.playlistPlaceholder()
                }
                .drive(coverImageView.rx.image(transitionType: CATransitionType.fade.rawValue))
                .disposed(by: rx.disposeBag)
            
        }
    }
    
}

class ArtistSectionHeader: UICollectionReusableView {
    
    @IBOutlet weak var label: UILabel!
    
}
