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

    func setupCollectionViewLayout(for size: CGSize) {
        guard self.isViewLoaded, let collectionViewFlowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let offset = collectionViewFlowLayout.minimumInteritemSpacing + collectionViewFlowLayout.sectionInset.left + collectionViewFlowLayout.sectionInset.right

        let viewRation = CGFloat(1.4125)
        let defaultItemWidth = CGFloat(177.0)

        if size.width < size.height {
            var itemSize = CGSize(width: defaultItemWidth, height: (defaultItemWidth * viewRation).rounded())
            if offset + 2 * itemSize.width > self.view.frame.width {
                itemSize.width = (size.width - offset) / 2
                itemSize.height = (itemSize.width * viewRation).rounded()
            }

            collectionViewFlowLayout.itemSize = itemSize

        } else {

            var itemSize = CGSize(width: defaultItemWidth, height: (defaultItemWidth / viewRation).rounded())
            if offset + 2 * itemSize.width > self.view.frame.width {
                itemSize.width = (size.width - offset) / 2
                itemSize.height = (itemSize.width / viewRation).rounded()
            }

            collectionViewFlowLayout.itemSize = itemSize
        }

        print("collectionViewFlowLayout.itemSize: \(collectionViewFlowLayout.itemSize)")
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupCollectionViewLayout(for: self.view.bounds.size)

        viewModel.load(with: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard self.isViewLoaded else { return }

        coordinator.animate(alongsideTransition: { (transitionCoordinatorContext) in

        }) { (transitionCoordinatorContext) in
            self.setupCollectionViewLayout(for: size)
            self.collectionView.collectionViewLayout.invalidateLayout()
            print("finish Transition to size")
        }
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        guard self.isViewLoaded else { return }

        coordinator.animate(alongsideTransition: { (transitionCoordinatorContext) in

        }) { (transitionCoordinatorContext) in
            self.setupCollectionViewLayout(for: self.view.bounds.size)
            self.collectionView.collectionViewLayout.invalidateLayout()
            
            print("finish Transition to newCollection")
        }
    }

}

// MARK: - UICollectionViewDatasource, UICollectionViewDelegate

extension PagesViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.numberOfItems(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let pageItemCollectionViewCell = PageItemCollectionViewCell.reusableCell(in: collectionView, at: indexPath)
        let pageItemViewModel = self.viewModel.item(at: indexPath)!

        pageItemCollectionViewCell.setup(viewModel: pageItemViewModel) { [unowned self, weak pageItemCollectionViewCell, weak collectionView] action in
            guard let pageItemCollectionViewCell = pageItemCollectionViewCell,
                let indexPath = collectionView?.indexPath(for: pageItemCollectionViewCell) else { return }

            switch action {
            case .delete: self.viewModel.deleteItem(at: indexPath)
            }

        }

        return pageItemCollectionViewCell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.viewModel.selectItem(at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {

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

    func reloadItemsUI(deletedAt: [IndexPath], insertedAt: [IndexPath], updatedAt: [IndexPath]) {
        self.collectionView.performBatchUpdates({

            if deletedAt.isEmpty == false { self.collectionView.deleteItems(at: deletedAt) }
            if insertedAt.isEmpty == false { self.collectionView.insertItems(at: insertedAt) }
            if updatedAt.isEmpty == false { self.collectionView.reloadItems(at: updatedAt) }

        }, completion: nil)
    }
}


extension PagesViewController: ZoomAnimatorSourceViewController {

    func transitionWillBegin(with animator: ZoomAnimator, for viewController: UIViewController) {

        self.view.layoutIfNeeded()

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

    func sourceImageContainerView(for animator: ZoomAnimator, for viewController: UIViewController) -> (UIView & ZoomAnimatorSourceImageContainerView)? {
//        self.collectionView.layoutIfNeeded()

        switch viewController {
        case let pageContentViewController as PageContentViewController:
            guard let pageIndexPath = self.viewModel.indexPath(for: pageContentViewController.viewModel.page),
                let cell = self.collectionView.cellForItem(at: pageIndexPath) as? PageItemCollectionViewCell else { return nil }
            return cell.containerView
        default: return nil
        }
    }
}
