//
//  PlaylistViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import RxDataSources

import DownloadButton

final class PlaylistViewController: UIViewController {

    lazy var dataSource = RxTableViewSectionedAnimatedDataSource<AnimatableSectionModel<String, TrackViewModel>>(configureCell: { [unowned self] (_, tableView, ip, data) in
        
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.trackTableViewCellIdentifier,
                                                 for: ip)!
        
        cell.trackView.setup(viewModel: data)
        
        return cell
        
    })
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var tableHeaderView: PlaylistTableHeaderView!
    @IBOutlet var emptyPlaylistView: UIView!

    var viewModel: PlaylistViewModel!

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = viewModel.headerViewModel.title
        
        tableView.register(R.nib.trackTableViewCell)
        
        tableHeaderView.setup(viewModel: viewModel.headerViewModel)
        
        viewModel.dataSource
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        viewModel.downloadButtonHidden
            .drive(tableHeaderView.downloadButton.rx.isHidden)
            .disposed(by: rx.disposeBag)
        
        viewModel.downloadViewModelDriver
            .flatMapLatest { $0.downloadPercent }
            .drive(onNext: { [weak d = tableHeaderView.downloadButton] (x) in
                d?.stopDownloadButton.progress = x
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.downloadViewModelDriver
            .flatMapLatest { $0.state }
            .drive(onNext: { [weak d = tableHeaderView.downloadButton] (x) in
                d?.state = x
            })
            .disposed(by: rx.disposeBag)
        
        tableView.rx.modelSelected(TrackViewModel.self)
            .subscribe(onNext: { [unowned self] (vm) in
                self.viewModel.trackSelected(track: vm.track)
            })
            .disposed(by: rx.disposeBag)
        
    }

    @IBAction func moreActions(_ sender: Any) {
        viewModel.showActions(sourceView: tableHeaderView.actionButton,
                              sourceRect: tableHeaderView.actionButton!.bounds)
    }
    
    @IBAction func playNow(_ sender: Any) {
        viewModel.playNow()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
}


// MARK: - UITableViewDataSource, UITableViewDelegate -

extension PlaylistViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView,
                          willDisplay cell: UITableViewCell,
                          forRowAt indexPath: IndexPath) {
        (cell as! TrackTableViewCell).trackView.prepareToDisplay()
    }

    public func tableView(_ tableView: UITableView,
                          didEndDisplaying cell: UITableViewCell,
                          forRowAt indexPath: IndexPath) {
        (cell as! TrackTableViewCell).trackView.prepareToEndDisplay()
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 58.0
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 0, self.viewModel.tracksViewModel.isPlaylistEmpty else {
            return 0.0
        }
        
        return 44.0
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0, self.viewModel.tracksViewModel.isPlaylistEmpty else { return nil }
        return self.emptyPlaylistView
    }
}

// MARK: - Router -
extension PlaylistViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        viewModel.router.prepare(for: segue, sender: sender)
        return super.prepare(for: segue, sender: sender)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if viewModel.router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
            return false
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

}

extension PlaylistViewController: PKDownloadButtonDelegate {

    func downloadButtonTapped(_ downloadButton: PKDownloadButton!, currentState state: PKDownloadButtonState) {
        switch state {
        case .startDownload:
            viewModel.downloadViewModel.value?.download()
            
        case .pending, .downloading:
            viewModel.downloadViewModel.value?.cancelDownload()
            
        case .downloaded:
            viewModel.openIn(sourceRect: downloadButton.frame, sourceView: tableHeaderView)
        }
    }
    
}
