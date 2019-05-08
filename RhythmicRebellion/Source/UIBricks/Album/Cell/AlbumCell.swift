//
//  AlbumCellViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/8/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

import RxSwift

class AlbumCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumDescriptionLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    
    fileprivate var disposeBag = DisposeBag()
    
    var viewModel: AlbumCellViewModel! {
        
        didSet {
            guard let vm = viewModel else {
                return
            }
            
            let a = vm.data.album
            
            albumDescriptionLabel.text = "By \(vm.data.artistName)"
            
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
    
    @IBAction func action(_ sender: Any) {
        viewModel.presentActions()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    
}
