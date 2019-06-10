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
    
    @IBOutlet weak var selectorView: UIView! {
        didSet {
            selectorView.isHidden = false
        }
    }
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var buttonsStack: UIStackView!
    
    @IBOutlet var sourceButtons: [UIButton]!
    
    lazy var dataSource = RxCollectionViewSectionedAnimatedDataSource<AnimatableSectionModel<String, ArtistViewModel.Data>>(configureCell: { [unowned self] (_, collectionView, ip, data) in
        
        switch data {
            
        case .album(let x):
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.albumCell,
                                                          for: ip)!
            
            cell.viewModel = x
            
            return cell
            
        case .playlist(let x):
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.albumCell,
                                                          for: ip)!
            
            cell.viewModel = x
            
            return cell
            
        case .track(let x):
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.trackCell,
                                                          for: ip)!
            
            cell.trackView.setup(viewModel: x)
            
            return cell
            
        }
        
    })
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = R.string.localizable.following()
        
        flowLayout.configureFor(bounds: view.bounds)
        
        collectionView.register(R.nib.albumCell)
        
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
        
        let rect = view.bounds
        viewModel.source.asDriver()
            .drive(onNext: { [weak self] (source) in
                
                self?.sourceButtons.forEach { x in
                    let isSelected = x.tag == source.rawValue
                    
                    x.setTitleColor(isSelected ? UIColor(fromHex: 0xFF3EA7) : .white, for: .normal)
                }
        
                UIView.animate(withDuration: 0.3, animations: {
                    self?.leadingConstraint.constant = CGFloat(source.rawValue) * rect.size.width / 3
                    self?.view.layoutIfNeeded()
                })
                
            })
            .disposed(by: rx.disposeBag)
        
    }
    
}

extension ArtistViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard viewModel.source.value == .songs else {
            return flowLayout.itemSize
        }

        return CGSize(width: collectionView.bounds.size.width,
                      height: 62)

    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        guard viewModel.source.value == .songs else {
            return 10
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        guard viewModel.source.value == .songs else {
            return flowLayout.sectionInset
        }
        
        return .zero
    }
    
    @IBAction func changeSource(_ sender: UIButton) {
        viewModel.change(sourceTag: sender.tag)
    }
    
}
