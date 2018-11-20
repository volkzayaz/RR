//
//  PageContentViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/15/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import WebKit

final class PageContentViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView?
    @IBOutlet weak var snapshotImageView: UIImageView?

    // MARK: - Public properties -

    private(set) var viewModel: PageContentViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: PageContentViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        let webView = WKWebView(frame: self.view.bounds)
        webView.backgroundColor = #colorLiteral(red: 0.0431372549, green: 0.07450980392, blue: 0.2274509804, alpha: 1)
        webView.navigationDelegate = self
        self.view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([webView.topAnchor.constraint(equalTo: self.view.topAnchor),
                                     webView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                                     webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                                     webView.rightAnchor.constraint(equalTo: self.view.rightAnchor)])

        self.webView = webView

        viewModel.load(with: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @objc func updateSnapshotImage() {
        guard let snapshotImage = self.webView?.makeSnapshotImage() else { return }

        self.viewModel.save(snapshotImage: snapshotImage)
    }

}

// MARK: - WKWebView

extension PageContentViewController: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

        self.snapshotImageView?.removeFromSuperview()
        if self.viewModel.isNeedUpdateSnapshotImage {
            self.perform(#selector(updateSnapshotImage), with: nil, afterDelay: 0.1)
        }
    }
}


// MARK: - Router -
extension PageContentViewController {

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

extension PageContentViewController: PageContentViewModelDelegate {

    func refreshUI() {

    }
    func reloadUI() {
        guard let url = self.viewModel.url else { return }

        let snapshotImageView = UIImageView(frame: self.view.bounds)
        snapshotImageView.contentMode = .scaleAspectFit
        snapshotImageView.image = self.viewModel.snapshotImage
        self.view.addSubview(snapshotImageView)
        snapshotImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([snapshotImageView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                                     snapshotImageView.topAnchor.constraint(equalTo: self.view.topAnchor),
                                     snapshotImageView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
                                     snapshotImageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)])

        self.snapshotImageView = snapshotImageView

        self.webView?.load(URLRequest(url: url))
    }

}

extension PageContentViewController: ZoomAnimatorDestinationViewController {

    func transitionWillBegin(with animator: ZoomAnimator) {

        if animator.isPresentation == false {
            self.webView?.stopLoading()
            if self.snapshotImageView == nil, let snapshotImage = self.webView?.makeSnapshotImage(afterScreenUpdates: false) {
                self.viewModel.save(snapshotImage: snapshotImage)
            }
        }

    }

    func transitionDidEnd(with animator: ZoomAnimator) {

    }

    func referenceImageView(for animator: ZoomAnimator) -> UIImageView? {
        return self.snapshotImageView
    }
}
