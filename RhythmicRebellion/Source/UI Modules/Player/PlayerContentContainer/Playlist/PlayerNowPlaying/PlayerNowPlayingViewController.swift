//
//  PlayerNowPlayingViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import EasyTipView

final class PlayerNowPlayingViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableHeaderView: PlayerNowPlayingTableHeaderView!

    // MARK: - Public properties -

    private(set) weak var tipView: TipView?

    private(set) var viewModel: PlayerNowPlayingViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: PlayerNowPlayingViewModel, router: FlowRouter) {
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

        self.tableView.register(UINib(nibName: "TrackTableViewCell", bundle: nil), forCellReuseIdentifier: TrackTableViewCell.identifier)
        self.tableView.tableHeaderView = self.tableHeaderView
        self.tableView.tableFooterView = UIView()

        viewModel.load(with: self)
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
        self.viewModel.reload()
    }

    func showActions(itemAt indexPath: IndexPath, sourceRect: CGRect, sourceView: UIView) {

        guard let actionsModel = viewModel.actions(forObjectAt: indexPath) else {
            return
        }

        let actionSheet = UIAlertController.make(from: actionsModel)

        actionSheet.popoverPresentationController?.sourceView = sourceView
        actionSheet.popoverPresentationController?.sourceRect = sourceRect

        self.present(actionSheet, animated: true, completion: nil)
    }

    func showOpenIn(itemAt indexPath: IndexPath, sourceRect: CGRect, sourceView: UIView) {

        guard let downloadedURL = self.viewModel.objectLoaclURL(at: indexPath) else { return }

        let activityViewController = UIActivityViewController(activityItems: [downloadedURL], applicationActivities: nil)

        activityViewController.popoverPresentationController?.sourceView = sourceView
        activityViewController.popoverPresentationController?.sourceRect = sourceRect

        self.present(activityViewController, animated: true, completion: nil)
    }

    func showHint(sourceView: UIView, text: String) {

        let tipView = TipView(text: text, preferences: EasyTipView.globalPreferences)
        tipView.showTouched(forView: sourceView, withinSuperview: self.tableView)

        self.tipView = tipView
    }

    func onTableViewHeaderAction(_ action: PlayerNowPlayingTableHeaderView.Actions) {

        guard let actionConfirmationViewModel = self.viewModel.confirmation(for: action) else { viewModel.perform(action: action); return }

        let confirmationAlertViewController = UIAlertController.make(from: actionConfirmationViewModel, style: .alert)
        self.present(confirmationAlertViewController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate -

extension PlayerNowPlayingViewController: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfItems(in: section)
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let trackItemTableViewCellViewModel = self.viewModel.object(at: indexPath)!
        (cell as! TrackTableViewCell).prepareToDisplay(viewModel: trackItemTableViewCellViewModel)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let trackItemTableViewCell = TrackTableViewCell.reusableCell(in: tableView, at: indexPath)
        let trackItemTableViewCellViewModel = self.viewModel.object(at: indexPath)!

        trackItemTableViewCell.setup(viewModel: trackItemTableViewCellViewModel) { [unowned self, weak trackItemTableViewCell, weak tableView] action in
            guard let trackItemTableViewCell = trackItemTableViewCell, let indexPath = tableView?.indexPath(for: trackItemTableViewCell) else { return }

            switch action {
            case .showActions:
                self.showActions(itemAt: indexPath,
                                 sourceRect: trackItemTableViewCell.actionButton.frame,
                                 sourceView: trackItemTableViewCell.actionButtonContainerView)
            case .download: self.viewModel.downloadObject(at: indexPath)
            case .cancelDownloading: self.viewModel.cancelDownloadingObject(at: indexPath)
            case .openIn(let sourceRect, let sourceView): self.showOpenIn(itemAt: indexPath,
                                          sourceRect: sourceRect,
                                          sourceView: sourceView)
            case .showHint(let sourceView, let hintText): self.showHint(sourceView: sourceView, text: hintText)
            }
        }

        return trackItemTableViewCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectObject(at: indexPath)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
}

// MARK: - Router -
extension PlayerNowPlayingViewController {

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

extension PlayerNowPlayingViewController: PlayerNowPlayingViewModelDelegate {

    func refreshUI() {

    }

    func reloadUI() {
        self.tableView.reloadData()
        self.refreshUI()
    }

    func reloadObjects(at indexPaths: [IndexPath]) {
        self.tableView.reloadRows(at: indexPaths, with: .none)
    }
}
