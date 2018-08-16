//
//  TrackItemTableViewCell.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol TrackTableViewCellViewModel {

    var id: String { get }

    var title: String { get }
    var description: String { get }

}

class TrackTableViewCell: UITableViewCell, CellIdentifiable {

    typealias ActionCallback = (Actions) -> Void

    enum Actions {
        case showFoliaActions
    }

    static let identifier = "TrackTableViewCellIdentifier"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!

    var viewModelId: String = ""

    var actionCallback: ActionCallback?

    func setup(viewModel: TrackTableViewCellViewModel, actionCallback:  @escaping ActionCallback) {

        self.viewModelId = viewModel.id

        self.titleLabel.text = viewModel.title
        self.descriptionLabel.text = viewModel.description

        self.actionCallback = actionCallback
    }

    // MARK: - Actions -

    @IBAction func onActionButton(sender: UIButton) {
        actionCallback?(.showFoliaActions)
    }
}