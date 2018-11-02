//
//  HomeViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var refreshControl: UIRefreshControl!
    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - Public properties -

    private(set) var viewModel: HomeViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: HomeViewModel, router: FlowRouter) {

        self.viewModel = viewModel
        self.router    = router

        if self.isViewLoaded { viewModel.load(with: self) }
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .top, barMetrics: .default)
        self.navigationController?.navigationBar.shadowImage = #colorLiteral(red: 0.2509803922, green: 0.2352941176, blue: 0.431372549, alpha: 1).image(CGSize(width: 0.5, height: 0.5))
        self.navigationController?.setNavigationBarHidden(true, animated: false)

        self.collectionView.addSubview(self.refreshControl)
        self.setupCollectionViewLayout()

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        viewModel.load(with: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func setupCollectionViewLayout() {
        guard let collectionViewFlowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let offset = collectionViewFlowLayout.minimumInteritemSpacing + collectionViewFlowLayout.sectionInset.left + collectionViewFlowLayout.sectionInset.right
        let viewWidth = min(self.view.bounds.width, self.view.bounds.height)
        let lineWidth = offset + 2 * collectionViewFlowLayout.itemSize.width
        if lineWidth > viewWidth {
            let itemWidth = (viewWidth - offset) / 2
            collectionViewFlowLayout.itemSize = CGSize(width: floor(itemWidth), height: (itemWidth / 1.10625).rounded())
        }
    }

    // MARK: - Actions

    @IBAction func onRefresh(sender: UIRefreshControl) {
        self.viewModel.reload()
    }

    func showActions(itemAt indexPath: IndexPath, sourceRect: CGRect, sourceView: UIView) {
        guard let actionsModel = viewModel.actions(forObjectAt: indexPath) else { return }
        self.show(alertActionsviewModel: actionsModel, sourceRect: sourceRect, sourceView: sourceView)
    }

    // MARK: - UICollectionViewDataSource -

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.numberOfItems(in: section)
    }


    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let playlistItemCollectionViewCell = PlaylistItemCollectionViewCell.reusableCell(in: collectionView, at: indexPath)
        let playlistItemViewModel = self.viewModel.object(at: indexPath)!

        playlistItemCollectionViewCell.setup(viewModel: playlistItemViewModel) { [unowned self, weak playlistItemCollectionViewCell, weak collectionView] action in
            guard let playlistItemCollectionViewCell = playlistItemCollectionViewCell, let indexPath = collectionView?.indexPath(for: playlistItemCollectionViewCell) else { return }

            switch action {
            case .showActions(let sourceRect, let sourcreView): self.showActions(itemAt: indexPath, sourceRect: sourceRect, sourceView: sourcreView)
            }
        }

        return playlistItemCollectionViewCell
    }


    // MARK: - UICollectionViewDelegate -

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.viewModel.selectObject(at: indexPath)
    }

}

// MARK: - Router -
extension HomeViewController {

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

extension HomeViewController: HomeViewModelDelegate {

    func refreshUI() {

    }

    func reloadUI() {
        self.collectionView.reloadData()
        self.refreshControl.endRefreshing()
        self.refreshUI()
    }
}
