//
//  PlaylistContentViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import AlamofireImage
import EasyTipView
import DownloadButton

final class PlaylistContentViewController: UIViewController {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var refreshControl: UIRefreshControl!
    @IBOutlet weak var tableHeaderView: PlaylistTableHeaderView!
    @IBOutlet var emptyPlaylistView: UIView!

    // MARK: - Public properties -

    private(set) weak var tipView: TipView?

    private(set) var viewModel: PlaylistViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: PlaylistViewModel, router: FlowRouter) {
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

        self.tableView.addSubview(self.refreshControl)
        self.setupTableHeaderView()
        self.tableView.tableFooterView = UIView()

        self.imageView.layer.cornerRadius = 6
        self.imageView.layer.masksToBounds = true

        tableView.register(R.nib.trackTableViewCell)
        
        viewModel.load(with: self)
        
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
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.tableHeaderView.updateFrame(in: self.tableView, for: self.traitCollection)
        self.tableView.tableHeaderView = self.tableHeaderView
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.tableHeaderView.updateFrame(in: self.tableView, for: self.traitCollection)
        self.tableView.tableHeaderView = self.tableHeaderView
    }

    func setupTableHeaderView() {

        self.tableHeaderView.updateFrame(in: self.tableView, for: self.traitCollection)
        self.tableView.tableHeaderView = self.tableHeaderView
    }

    // MARK: - Actions -

    @IBAction func onRefresh(sender: UIRefreshControl) {
        self.viewModel.tracksViewModel.reload()
    }

    func showPlaylistActions(sourceRect: CGRect, sourceView: UIView) {
        guard let actionsModel = viewModel.playlistActions() else {  return }

        self.show(alertActionsviewModel: actionsModel, sourceRect: sourceRect, sourceView: sourceView)
    }

    func showActions(itemAt indexPath: IndexPath, sourceRect: CGRect, sourceView: UIView) {
        let actionsModel = viewModel.tracksViewModel.actions(forObjectAt: indexPath)

        self.show(alertActionsviewModel: actionsModel, sourceRect: sourceRect, sourceView: sourceView)
    }

    func showHint(sourceView: UIView, text: String) {

        let tipView = TipView(text: text, preferences: EasyTipView.globalPreferences)
        tipView.showTouched(forView: sourceView, in: self.tableView)

        self.tipView = tipView
    }
}


// MARK: - UITableViewDataSource, UITableViewDelegate -

extension PlaylistContentViewController: UITableViewDataSource, UITableViewDelegate {


    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.tracksViewModel.numberOfItems(in: section)
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as! TrackTableViewCell).trackView.prepareToDisplay()
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as! TrackTableViewCell).trackView.prepareToEndDisplay()
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let trackItemTableViewCell = TrackTableViewCell.reusableCell(in: tableView, at: indexPath)
        let trackItemTableViewCellViewModel = self.viewModel.tracksViewModel.object(at: indexPath)

        trackItemTableViewCell.trackView.setup(viewModel: trackItemTableViewCellViewModel) { [unowned self, weak trackItemTableViewCell, weak tableView] action in
            guard let trackItemTableViewCell = trackItemTableViewCell, let indexPath = tableView?.indexPath(for: trackItemTableViewCell) else { return }

            switch action {
            case .showActions:
                self.showActions(itemAt: indexPath,
                                 sourceRect: trackItemTableViewCell.trackView.actionButton.frame,
                                 sourceView: trackItemTableViewCell.trackView.actionButtonContainerView)
            
            case .showHint(let sourceView, let hintText): self.showHint(sourceView: sourceView, text: hintText)
            }
        }

        return trackItemTableViewCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.tracksViewModel.selectObject(at: indexPath)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 0, self.viewModel.tracksViewModel.isPlaylistEmpty else { return 0.0 }
        return 44.0
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0, self.viewModel.tracksViewModel.isPlaylistEmpty else { return nil }
        return self.emptyPlaylistView
    }
}

// MARK: - Router -
extension PlaylistContentViewController {

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

extension PlaylistContentViewController: TrackListBindings {

    func reloadPlaylistUI() {
        let playlistHeaderViewModel = self.viewModel.playlistHeaderViewModel

        self.tableHeaderView.setup(viewModel: self.viewModel.playlistHeaderViewModel) { [unowned self] (action) in

            switch action {
            case .showActions: self.showPlaylistActions(sourceRect: self.tableHeaderView.actionButton.bounds, sourceView: self.tableHeaderView.actionButton)
            case .clear: self.viewModel.clearPlaylist()
            }
        }

        if let thumbnailURL = playlistHeaderViewModel.thumbnailURL, self.imageView.superview != nil {
            self.activityIndicatorView.startAnimating()
            self.imageView.af_setImage(withURL: thumbnailURL,
                                       filter: ScaledToSizeFilter(size: CGSize(width: 360, height: 360))) { [weak self] (thumbnailImageResponse) in

                                        guard let `self` = self else {
                                            return
                                        }
                                        switch thumbnailImageResponse.result {
                                        case .success(let thumbnailImage):
                                            self.imageView.image = thumbnailImage

                                        default: break
                                        }

                                        self.activityIndicatorView.stopAnimating()
            }
        } else {
            self.imageView.makePlaylistPlaceholder()
            self.activityIndicatorView.stopAnimating()
        }

        self.navigationItem.title = playlistHeaderViewModel.title
    }

    func reloadUI() {
        self.tableView.reloadData()
        self.refreshControl.endRefreshing()
    }

    func reloadObjects(at indexPaths: [IndexPath]) {
        self.tableView.reloadRows(at: indexPaths, with: .none)
    }

}

extension PlaylistContentViewController: PKDownloadButtonDelegate {

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
