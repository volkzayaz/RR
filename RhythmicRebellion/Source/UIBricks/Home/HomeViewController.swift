//
//  HomeViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

import RxDataSources

final class HomeViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    lazy var dataSource = RxCollectionViewSectionedAnimatedDataSource<AnimatableSectionModel<String, TrackGroupViewModel<DefinedPlaylist>>>(configureCell: { [unowned self] (_, collectionView, ip, data) in

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.albumCell,
                                                      for: ip)!
        
        cell.viewModel = data
        
        return cell
        
    })
    
    var viewModel: HomeViewModel!

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .top, barMetrics: .default)
        self.navigationController?.navigationBar.shadowImage = #colorLiteral(red: 0.2509803922, green: 0.2352941176, blue: 0.431372549, alpha: 1).image(CGSize(width: 0.5, height: 0.5))
        self.navigationController?.setNavigationBarHidden(true, animated: false)

        self.setupCollectionViewLayout()

        collectionView.register(R.nib.albumCell)
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

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

        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func setupCollectionViewLayout() {
        
        (collectionView.collectionViewLayout as? BaseFlowLayout)?
            .configureFor(bounds: view.bounds)
        
    }

}
