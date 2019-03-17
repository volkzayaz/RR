//
//  NowPlayingViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import EasyTipView

import RxSwift
import RxCocoa
import RxDataSources

import Rswift

final class NowPlayingViewController: UIViewController {

    lazy var dataSource = RxTableViewSectionedAnimatedDataSource<AnimatableSectionModel<String, TrackViewModel>>(configureCell: { [unowned self] (_, tableView, ip, data) in
        
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.trackTableViewCellIdentifier,
                                        for: ip)!
        
        let f = cell.trackView.actionButton.frame
        let v = cell.trackView.actionButtonContainerView
        
        cell.trackView.setup(viewModel: data) { [unowned self, unowned c = cell, unowned tv = tableView] action in
            
            switch action {
            case .showActions:
                self.showActions(itemAt: tv.indexPath(for: c)!,
                                 sourceRect: f,
                                 sourceView: v!)
                
            case .showHint(let sourceView, let hintText):
                self.showHint(sourceView: sourceView, text: hintText)
            }
        }
        
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

        var tipViewPreferences = EasyTipView.Preferences()
        tipViewPreferences.drawing.font = UIFont.systemFont(ofSize: 12.0)
        tipViewPreferences.drawing.foregroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        tipViewPreferences.drawing.backgroundColor = #colorLiteral(red: 0.2089539468, green: 0.1869146228, blue: 0.349752754, alpha: 1)
        tipViewPreferences.animating.showInitialAlpha = 0
        tipViewPreferences.animating.showDuration = 1.5
        tipViewPreferences.animating.dismissDuration = 1.5
        tipViewPreferences.positioning.textHInset = 5.0
        tipViewPreferences.positioning.textVInset = 5.0
        EasyTipView.globalPreferences = tipViewPreferences

        self.tableHeaderView.setup { [unowned self] (action) in
            self.onTableViewHeaderAction(action)
        }

        tableView.register(R.nib.trackTableViewCell)
        
        self.tableView.tableHeaderView = self.tableHeaderView
        self.tableView.tableFooterView = UIView()

        viewModel.dataSource
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { (transitionCoordinatorContext) in
            self.tipView?.updateFrame()
        }) { (transitionCoordinatorContext) in
            self.tipView?.dismissTouched()
        }
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
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

    func showActions(itemAt indexPath: IndexPath, sourceRect: CGRect, sourceView: UIView) {

        let actionsModel = viewModel.tracksViewModel.actions(forObjectAt: indexPath)
        
        let actionSheet = UIAlertController.make(from: actionsModel)

        actionSheet.popoverPresentationController?.sourceView = sourceView
        actionSheet.popoverPresentationController?.sourceRect = sourceRect

        self.present(actionSheet, animated: true, completion: nil)
    }

    func showHint(sourceView: UIView, text: String) {

        let tipView = TipView(text: text, preferences: EasyTipView.globalPreferences)
        tipView.showTouched(forView: sourceView, in: self.tableView)

        self.tipView = tipView
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.tracksViewModel.selectObject(at: indexPath)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
//
//    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        guard section == 0, self.viewModel.tracksViewModel.isPlaylistEmpty else { return 0.0 }
//        return 44.0
//    }
//
//    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        guard section == 0, self.viewModel.tracksViewModel.isPlaylistEmpty else { return nil }
//        return self.emptyPlaylistView
//    }
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

extension NowPlayingViewController: TrackListBindings {

    func reloadUI() {
        //self.tableView.reloadData()
    }

    func reloadPlaylistUI() {
        guard self.viewModel.tracksViewModel.isPlaylistEmpty == false else { self.tableView.tableHeaderView = nil; return }
        self.tableView.tableHeaderView = self.tableHeaderView
    }

    func reloadObjects(at indexPaths: [IndexPath]) {
        //self.tableView.reloadRows(at: indexPaths, with: .none)
    }
}
