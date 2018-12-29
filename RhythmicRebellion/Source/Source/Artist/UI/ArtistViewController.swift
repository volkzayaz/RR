//
//  ArtistViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/28/18.
//Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

class ArtistViewController: UIViewController, MVVM_View {
    
    var viewModel: ArtistViewModel!
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    
    @IBOutlet weak var flowLayout: BaseFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    
    lazy var dataSource = RxCollectionViewSectionedAnimatedDataSource<AnimatableSectionModel<String, ArtistViewModel.Data>>(configureCell: { [unowned self] (_, collectionView, ip, data) in
        
        switch data {
            
        case .album(let x):
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.albumCell,
                                                          for: ip)!
            
            cell.album = x
            cell.artist = self.viewModel.artistName
            
            return cell
            
        case .playlist(let x):
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.playlistItemCollectionViewCellIdentifier,
                                                          for: ip)!
            
            let input = PlaylistItemViewModel(playlist: x, showActivity: true)
            
            cell.setup(viewModel: input) { action in
                print(action)
            }
            
            return cell
            
        case .track(let x):
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.trackCell,
                                                          for: ip)!
            
            cell.trackView.setup(viewModel: x) { _ in }
            
            cell.trackView.backwardCompatibilityViewModel = self.viewModel
            cell.trackView.indexPath = ip
            
            return cell
            
        }
        
    })
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        flowLayout.configureFor(bounds: view.bounds)
        
        collectionView.register(R.nib.playlistCollectionCell)
        
        viewModel.dataSource
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        collectionView.rx.willDisplayCell
            .map { $0.cell as? TrackCollectionViewCell }
            .notNil()
            .subscribe(onNext: { $0.trackView.prepareToDisplay() })
            .disposed(by: rx.disposeBag)
        
        collectionView.rx.didEndDisplayingCell
            .map { $0.cell as? TrackCollectionViewCell }
            .notNil()
            .subscribe(onNext: { $0.trackView.prepareToEndDisplay() })
            .disposed(by: rx.disposeBag)
        
        collectionView.rx.modelSelected(ArtistViewModel.Data.self)
            .subscribe(onNext: { [weak self] x in
                self?.viewModel.selected(item: x)
            })
            .disposed(by: rx.disposeBag)
        
    }
    
}

extension ArtistViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard indexPath.section == 2 else {
            return flowLayout.itemSize
        }
        
        return CGSize(width: collectionView.bounds.size.width,
                      height: 44)
        
    }
    
}
