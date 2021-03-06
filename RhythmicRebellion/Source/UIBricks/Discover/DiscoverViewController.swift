//
//  DiscoverViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

import RxDataSources

final class DiscoverViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    lazy var dataSource = RxCollectionViewSectionedAnimatedDataSource<AnimatableSectionModel<String, TrackGroupViewModel<DefinedPlaylist>>>(configureCell: { [unowned self] (_, collectionView, ip, data) in

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.albumCell,
                                                      for: ip)!
        
        cell.viewModel = data
        
        return cell
        
    }, configureSupplementaryView: { (_, cv, kind, ip) in
        
        let view = cv.dequeueReusableSupplementaryView(ofKind: kind,
                                                       withReuseIdentifier: R.reuseIdentifier.bestForYou.identifier,
                                                       for: ip)
        return view
    })
    
    lazy var viewModel: DiscoverViewModel! = DiscoverViewModel(router: .init(owner: self))

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        (collectionView.collectionViewLayout as? BaseFlowLayout)?
            .configureFor(bounds: view.bounds)
        
        (collectionView.collectionViewLayout as? BaseFlowLayout)?.headerReferenceSize = CGSize(width: 0, height: 45)

        collectionView.register(R.nib.albumCell)
        
        viewModel.dataSource
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        collectionView.rx.modelSelected(TrackGroupViewModel<DefinedPlaylist>.self)
            .subscribe(onNext: { [weak self] x in
                self?.viewModel.select(viewModel: x)
            })
            .disposed(by: rx.disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

}
