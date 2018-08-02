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

final class PlaylistContentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableHeaderView: PlaylistTableHeaderView!

    // MARK: - Public properties -

    private(set) var viewModel: PlaylistContentViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: PlaylistContentViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupTableHeaderView()
        self.tableView.tableFooterView = UIView()

        self.imageView.layer.cornerRadius = 6
        self.imageView.layer.masksToBounds = true

        viewModel.load(with: self)

        let playlistHeaderViewModel = self.viewModel.playlistHeaderViewModel

        self.tableHeaderView.setup(viewModel: playlistHeaderViewModel)

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
        }

        self.navigationItem.title = playlistHeaderViewModel.title

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.layoutTableHeaderView()
        self.tableView.tableHeaderView = self.tableHeaderView
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.layoutTableHeaderView()
        self.tableView.tableHeaderView = self.tableHeaderView
    }

    func setupTableHeaderView() {

        self.layoutTableHeaderView()
        self.tableHeaderView.translatesAutoresizingMaskIntoConstraints = true
        self.tableView.tableHeaderView = self.tableHeaderView
    }

    func layoutTableHeaderView() {

        var tableHeaderViewFrame = self.tableHeaderView.frame
        if self.traitCollection.horizontalSizeClass == .compact {
            tableHeaderViewFrame.size.height = self.tableView.frame.size.width * 0.85
        } else if self.traitCollection.horizontalSizeClass == .regular {
            tableHeaderViewFrame.size.height = 93.0
        }
        self.tableHeaderView.frame = tableHeaderViewFrame
    }


    // MARK: - UITableViewDataSource -
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfItems(in: section)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let trackItemTableViewCell = TrackItemTableViewCell.reusableCell(in: tableView, at: indexPath)
        let trackItemTableViewCellViewModel = self.viewModel.object(at: indexPath)!

        trackItemTableViewCell.settup(viewModel: trackItemTableViewCellViewModel)

        return trackItemTableViewCell
    }

    // MARK: - UITableViewDelegate -

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
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

extension PlaylistContentViewController: PlaylistContentViewModelDelegate {

    func refreshUI() {

    }

    func reloadUI() {

        self.tableView.reloadData()
        self.refreshUI()
    }
}
