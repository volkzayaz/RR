//
//  PagesViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class PagesViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - Public properties -

    private(set) var viewModel: PagesViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: PagesViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    func setupCollectionViewLayout() {
        guard let collectionViewFlowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let offset = collectionViewFlowLayout.minimumInteritemSpacing + collectionViewFlowLayout.sectionInset.left + collectionViewFlowLayout.sectionInset.right

        let defaultItemWidth = CGFloat(177.0)

        if self.view.frame.width < self.view.frame.height {
            let viewRation = CGFloat(1.4125)
            var itemSize = CGSize(width: defaultItemWidth, height: (defaultItemWidth * viewRation).rounded())
            if offset + 2 * itemSize.width > self.view.frame.width {
                itemSize.width = (self.view.frame.width - offset) / 2
                itemSize.height = (itemSize.width * viewRation).rounded()
            }

            collectionViewFlowLayout.itemSize = itemSize

        } else {
            let viewRation = CGFloat(1.4125)
            var itemSize = CGSize(width: (defaultItemWidth * viewRation).rounded(), height: defaultItemWidth)
            if offset + 2 * itemSize.width > self.view.frame.width {
                itemSize.width = (self.view.frame.width - offset) / 2
                itemSize.height = (itemSize.width / viewRation).rounded()
            }

            collectionViewFlowLayout.itemSize = itemSize
        }
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupCollectionViewLayout()

        viewModel.load(with: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//
//        self.setupCollectionViewLayout()
//        self.collectionView.collectionViewLayout.invalidateLayout()
//
//        coordinator.animate(alongsideTransition: { (transitionCoordinatorContext) in
//
//        }) { (transitionCoordinatorContext) in
//
//        }
//    }
//
//    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.willTransition(to: newCollection, with: coordinator)
//
//        self.setupCollectionViewLayout()
//        self.collectionView.collectionViewLayout.invalidateLayout()
//
//        coordinator.animate(alongsideTransition: { (transitionCoordinatorContext) in
//
//        }) { (transitionCoordinatorContext) in
//
//        }
//    }

}

// MARK: - UICollectionViewDatasource, UICollectionViewDelegate

extension PagesViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.numberOfItems(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let pageItemCollectionViewCell = PageItemCollectionViewCell.reusableCell(in: collectionView, at: indexPath)
        let pageItemViewModel = self.viewModel.object(at: indexPath)!

        pageItemCollectionViewCell.setup(viewModel: pageItemViewModel) { [unowned self, weak pageItemCollectionViewCell, weak collectionView] action in
            guard let pageItemCollectionViewCell = pageItemCollectionViewCell,
                let indexPath = collectionView?.indexPath(for: pageItemCollectionViewCell) else { return }

        }

        return pageItemCollectionViewCell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.viewModel.selectObject(at: indexPath)
    }
}

// MARK: - Router -
extension PagesViewController {

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

extension PagesViewController: PagesViewModelDelegate {

    func refreshUI() {

    }

    func reloadUI() {
        self.collectionView.reloadData()
    }

    func reloadItem(at indexPath: IndexPath) {
        self.collectionView.reloadItems(at: [indexPath])
    }

}


extension PagesViewController: ZoomAnimatorSourceViewController {

    func transitionWillBegin(with animator: ZoomAnimator, for viewController: UIViewController) {
        switch viewController {
        case let pageContentViewController as PageContentViewController:
            guard let pageIndexPath = self.viewModel.indexPath(for: pageContentViewController.viewModel.page),
                self.collectionView.indexPathsForVisibleItems.contains(pageIndexPath) == false else { break }

            self.collectionView.scrollToItem(at: pageIndexPath, at: [], animated: false)

        default: break
        }
    }

    func transitionDidEnd(with animator: ZoomAnimator, for viewController: UIViewController) {

    }

    func referenceImageView(for animator: ZoomAnimator, for viewController: UIViewController) -> UIImageView? {
        self.collectionView.layoutIfNeeded()

        switch viewController {
        case let pageContentViewController as PageContentViewController:
            guard let pageIndexPath = self.viewModel.indexPath(for: pageContentViewController.viewModel.page),
                let cell = self.collectionView.cellForItem(at: pageIndexPath) as? PageItemCollectionViewCell else { return nil }
            return cell.imageView
        default: return nil
        }
    }

    func frame(for viewController: UIViewController) -> CGRect? {
        self.collectionView.layoutIfNeeded()

        switch viewController {
        case let pageContentViewController as PageContentViewController:
            guard let pageIndexPath = self.viewModel.indexPath(for: pageContentViewController.viewModel.page),
                let cell = self.collectionView.cellForItem(at: pageIndexPath) as? PageItemCollectionViewCell else { return nil }

            let frame = self.collectionView.convert(cell.frame, to: self.view)

            if frame.minY < self.collectionView.contentInset.top {
                return CGRect(x: frame.minX, y: self.collectionView.contentInset.top, width: frame.width, height: frame.height - (self.collectionView.contentInset.top - frame.minY))
            }

            return frame

        default: return nil
        }
    }
}
