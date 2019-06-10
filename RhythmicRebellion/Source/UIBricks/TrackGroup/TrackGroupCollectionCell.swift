//
//  TrackGroupCollectionCell.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/8/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

import RxSwift

protocol TrackGroupViewModelProtocol {
    
    var present: TrackGroupPresentable { get }
    
    func presentActions()
    
}

class TrackGroupCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumDescriptionLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    
    fileprivate var disposeBag = DisposeBag()
    
    var viewModel: TrackGroupViewModelProtocol! {
        
        didSet {
            guard let vm = viewModel else {
                return
            }
            
            albumNameLabel.text = vm.present.name
            albumDescriptionLabel.text = vm.present.subtitle
            
            ImageRetreiver.imageForURLWithoutProgress(url: vm.present.imageURL)
                .map { [weak v = coverImageView] x -> UIImage? in
                    if let x = x {
                        v?.contentMode = .scaleAspectFill
                        return x
                    }
                    
                    v?.contentMode = .center
                    return R.image.cover_placeholder()
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
