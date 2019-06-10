//
//  NowPlayingViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

class NowPlayingViewController: UIViewController {

    lazy var dataSource = RxTableViewSectionedAnimatedDataSource<AnimatableSectionModel<String, TrackViewModel>>(configureCell: { [unowned self] (_, tableView, ip, data) in
        
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.trackTableViewCellIdentifier,
                                        for: ip)!
        
        cell.trackView.setup(viewModel: data)
        
        return cell

    })
    
    @IBOutlet var clearBarButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!

    var viewModel: NowPlayingViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(R.nib.trackTableViewCell)
        navigationItem.rightBarButtonItem = clearBarButton
        
        viewModel.dataSource
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        tableView.rx.modelSelected(TrackViewModel.self)
            .subscribe(onNext: { [unowned self] (vm) in
                self.viewModel.selected(orderedTrack: vm.trackRepresentation.providable as! OrderedTrack)
            })
            .disposed(by: rx.disposeBag)
    }

    @IBAction func clear(_ sender: Any) {
        Dispatcher.dispatch(action: ClearTracks())
    }
    
}

extension NowPlayingViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as! TrackTableViewCell).trackView.prepareToDisplay()
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as! TrackTableViewCell).trackView.prepareToEndDisplay()
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 58.0
    }

}
