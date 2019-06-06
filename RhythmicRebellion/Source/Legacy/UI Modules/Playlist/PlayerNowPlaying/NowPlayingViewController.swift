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

import Rswift

final class NowPlayingViewController: UIViewController {

    lazy var dataSource = RxTableViewSectionedAnimatedDataSource<AnimatableSectionModel<String, TrackViewModel>>(configureCell: { [unowned self] (_, tableView, ip, data) in
        
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.trackTableViewCellIdentifier,
                                        for: ip)!
        
        cell.trackView.setup(viewModel: data)
        
        return cell

    })
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableHeaderView: PlayerNowPlayingTableHeaderView!
    @IBOutlet var emptyPlaylistView: UIView!

    // MARK: - Public properties -

    private(set) weak var tipView: TipView?

    private(set) var viewModel: NowPlayingViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: NowPlayingViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
        
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableHeaderView.setup { [unowned self] (action) in
            self.onTableViewHeaderAction(action)
        }

        tableView.register(R.nib.trackTableViewCell)
        
        self.tableView.tableHeaderView = self.tableHeaderView
        self.tableView.tableFooterView = UIView()

        viewModel.dataSource
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        tableView.rx.modelSelected(TrackViewModel.self)
            .subscribe(onNext: { [unowned self] (vm) in
                self.viewModel.selected(orderedTrack: vm.trackProvidable as! OrderedTrack)
            })
            .disposed(by: rx.disposeBag)
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { (transitionCoordinatorContext) in
            self.tipView?.updateFrame()
        }) { (transitionCoordinatorContext) in
            self.tipView?.dismissTouched()
        }
    }

    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        coordinator.animate(alongsideTransition: { (transitionCoordinatorContext) in
            self.tipView?.updateFrame()
        }) { (transitionCoordinatorContext) in
            self.tipView?.dismissTouched()
        }
    }

    // MARK: - Actions -
    @IBAction func onRefresh(sender: UIRefreshControl) {
        self.viewModel.tracksViewModel.reload()
    }

    func onTableViewHeaderAction(_ action: PlayerNowPlayingTableHeaderView.Actions) {

        guard let actionConfirmationViewModel = self.viewModel.confirmation(for: action) else { viewModel.perform(action: action); return }

        let confirmationAlertViewController = UIAlertController.make(from: actionConfirmationViewModel, style: .alert)
        self.present(confirmationAlertViewController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate -

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

// MARK: - Router -
extension NowPlayingViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        router.prepare(for: segue, sender: sender)
        return super.prepare(for: segue, sender: sender)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
            return false
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

}
