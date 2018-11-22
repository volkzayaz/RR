//
//  PromoViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PromoViewModel: class {

    var artistName: String? { get }
    var trackName: String? { get }

    var infoText: String? { get }

    var writerName: String? { get }

    var isAddonsSkipped: Bool { get }

    var canVisitArtistSite: Bool { get }
    var canVisitWriterSite: Bool { get }

    var canToggleSkipAddons: Bool { get }

    func load(with delegate: PromoViewModelDelegate)

    func thumbnailURL() -> URL?

    func setSkipAddons(skip: Bool)

    func visitArtistSite()
    func visitWriterSite()

    func navigateToAuthorization()
}

protocol PromoViewModelDelegate: class, ErrorPresenting {

    func refreshUI()

}
