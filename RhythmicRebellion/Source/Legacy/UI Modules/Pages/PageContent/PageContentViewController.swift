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

    private var updateSnapshotTimer: Timer?

    // MARK: - Configuration -

    func configure(viewModel: PageContentViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    deinit {
        print("PageContentViewController: deinit")

        for commandName in self.viewModel.handledCommandsNames {
            self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: commandName)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let webView = WKWebView(frame: self.view.bounds)
        webView.backgroundColor = #colorLiteral(red: 0.0431372549, green: 0.07450980392, blue: 0.2274509804, alpha: 1)
        webView.scrollView.backgroundColor = #colorLiteral(red: 0.0431372549, green: 0.07450980392, blue: 0.2274509804, alpha: 1)
        webView.isOpaque = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
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
        guard let webView = self.webView, let snapshotImage = webView.makeSnapshotImage(for: webView.bounds) else { return }

        self.viewModel.save(snapshotImage: snapshotImage)
    }

}

// MARK: - WKWebView

extension PageContentViewController: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        print("Wants to create new WEBVIEW!!!!!!")

        return nil
    }
}

extension PageContentViewController: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

        self.snapshotImageView?.removeFromSuperview()
        if self.viewModel.isNeedUpdateSnapshotImage {
            self.updateSnapshotTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { [weak self] (timer) in
                self?.updateSnapshotImage()
            })
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView error: \(error)")
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError error: Error) {
        self.viewModel.webViewFailed(with: error)
    }

    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("didReceiveServerRedirectForProvisionalNavigation: \(String(describing: navigation))")
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

    func configure(with scripts: [WKUserScript], commandHandlers: [String : WKScriptMessageHandler]) {

        scripts.forEach { self.webView?.configuration.userContentController.addUserScript($0) }
        commandHandlers.forEach { self.webView?.configuration.userContentController.add($0.value, name: $0.key) }
    }

    func reloadUI() {
        guard let url = self.viewModel.url else { return }

        let snapshotImageView = UIImageView(frame: self.view.bounds)
        snapshotImageView.contentMode = .scaleAspectFill
        snapshotImageView.image = self.viewModel.snapshotImage
        self.view.addSubview(snapshotImageView)
        snapshotImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([snapshotImageView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                                     snapshotImageView.topAnchor.constraint(equalTo: self.view.topAnchor),
                                     snapshotImageView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
                                     snapshotImageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)])

        self.snapshotImageView = snapshotImageView

        let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)
        self.webView?.load(request)
        print("Start load URL: \(url)")
    }

    func evaluateJavaScript(javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        self.webView?.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
}

extension PageContentViewController: ZoomAnimatorDestinationViewController {

    func transitionWillBegin(with animator: ZoomAnimator) {

        if animator.isPresentation == false {
            self.webView?.stopLoading()

            if self.snapshotImageView == nil, self.viewModel.isNeedUpdateSnapshotImage == true, let webView = self.webView {
                self.updateSnapshotTimer?.invalidate()
                if let snapshotImage = webView.makeSnapshotImage(for: webView.bounds, afterScreenUpdates: false) {
                    self.viewModel.save(snapshotImage: snapshotImage)
                }
            }
        }

    }

    func transitionDidEnd(with animator: ZoomAnimator) {
        if let snapshotImageView = self.snapshotImageView {
            snapshotImageView.isHidden = true
        }
    }

    func referenceImageView(for animator: ZoomAnimator) -> UIImageView? {
        return self.snapshotImageView
    }


}
