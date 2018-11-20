//
//  PageContentViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/15/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PageContentViewModel: class {

    var page: Page { get }

    var url: URL? { get }
    var snapshotImage: UIImage? { get }
    var isNeedUpdateSnapshotImage: Bool { get }

    func load(with delegate: PageContentViewModelDelegate)
    func save(snapshotImage: UIImage)

}

protocol PageContentViewModelDelegate: class {

    func refreshUI()
    func reloadUI()
}
