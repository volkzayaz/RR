//
//  AlbumCollectionCell.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import RxSwift

class AlbumCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumDescriptionLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    
    fileprivate var disposeBag = DisposeBag()
    
    var album: Album! {
        
        didSet {
            guard let a = album else {
                return
            }
            
            albumNameLabel.text = a.name
            
            ImageRetreiver.imageForURLWithoutProgress(url: a.image.simpleURL ?? "")
                .map { [weak v = coverImageView] x -> UIImage? in
                    if let x = x {
                        v?.contentMode = .scaleAspectFill
                        return x
                    }
                    
                    v?.contentMode = .center
                    return R.image.playlistPlaceholder()
                }
                .drive(coverImageView.rx.image(transitionType: CATransitionType.fade.rawValue))
                .disposed(by: disposeBag)
            
        }
        
    }
    
    var artist: String? {
        didSet {
            
            guard let a = artist else {
                albumDescriptionLabel.text = nil
                return
            }
            
            albumDescriptionLabel.text = "By \(a)"
        }
    }
    
    var action: ( () -> () )? = nil
    
    @IBAction func action(_ sender: Any) {
        action?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    
}
