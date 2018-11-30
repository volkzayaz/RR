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

    var url: URL? { get }
    var snapshotImage: UIImage? { get }
    var isNeedUpdateSnapshotImage: Bool { get }

    func load(with delegate: PageContentViewModelDelegate)
    func save(snapshotImage: UIImage)
}

protocol PageContentViewModelDelegate: class, ErrorPresenting {

    func refreshUI()

    func configure(with scripts: [WKUserScript], messageHandlers: [String : WKScriptMessageHandler])

    func reloadUI()

    func evaluateJavaScript(javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)

    

}
