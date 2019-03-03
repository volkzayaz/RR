//
//  PageContentViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/15/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import WebKit

protocol PageContentViewModel: class {

    var page: Page { get }

    var handledCommandsNames: [String] { get }

    var url: URL? { get }
    var snapshotImage: UIImage? { get }
    var isNeedUpdateSnapshotImage: Bool { get }

    func load(with delegate: PageContentViewModelDelegate)

    func snapshotRect(for bounds: CGRect) -> CGRect
    func save(snapshotImage: UIImage)

    func webViewFailed(with error: Error)
}

protocol PageContentViewModelDelegate: class, ErrorPresenting {

    func refreshUI()

    func configure(with scripts: [WKUserScript], commandHandlers: [String : WKScriptMessageHandler])

    func reloadUI()

    func evaluateJavaScript(javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)

    

}
