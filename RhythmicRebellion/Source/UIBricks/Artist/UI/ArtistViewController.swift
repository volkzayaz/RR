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
        
    }, configureSupplementaryView: { [weak self] (_, cv, kind, ip) -> UICollectionReusableView in
        
        guard ip.section == 0 else {
            
            let view = cv.dequeueReusableSupplementaryView(ofKind: kind,
                                                           withReuseIdentifier: R.reuseIdentifier.artistSectionHeader, for: ip)!
            
            view.label.text = self?.viewModel.title(for: ip.section)
            
            return view
        }
        
        let view = cv.dequeueReusableSupplementaryView(ofKind: kind,
                                                       withReuseIdentifier: R.reuseIdentifier.artistCoverHeader, for: ip)!
        
        view.coverURL = self?.viewModel.artistCoverURL
        view.artistNameLabel.text = self?.viewModel.artistName
        view.sectionNameLabel.text = self?.viewModel.title(for: 0)
        
        return view
        
    })
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = R.string.localizable.following()
        
        flowLayout.configureFor(bounds: view.bounds)
        
        collectionView.register(R.nib.playlistCollectionCell)
        collectionView.register(R.nib.artistSectionHeader,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        collectionView.register(R.nib.artistCoverHeader,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        
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

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        guard section == 2 else {
            return 10
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        guard section == 2 else {
            return flowLayout.sectionInset
        }
        
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        guard section == 0 else {
            return CGSize(width: collectionView.bounds.size.width, height: 39)
        }
        
        return CGSize(width: collectionView.bounds.size.width, height: 270)
        
    }
    
}
