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
    var isPlayable: Bool { get }
    var isCurrentInPlayer: Bool { get }
    var isPlaying: Bool { get }
}

class TrackTableViewCell: UITableViewCell, CellIdentifiable {

    typealias ActionCallback = (Actions) -> Void

    enum Actions {
        case showFoliaActions
    }

    static let identifier = "TrackTableViewCellIdentifier"

    @IBOutlet weak var equalizer: EqualizerView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    @IBOutlet weak var actionButtonContainerView: UIView!
    @IBOutlet weak var actionButtonContainerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionButtonConatinerViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionButton: UIButton!

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet var stackViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackViewTrailingConstraint: NSLayoutConstraint!

    @IBOutlet weak var equalizerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var equalizerWidthConstraint: NSLayoutConstraint!
    
    var viewModelId: String = ""

    var actionCallback: ActionCallback?

    func prepareToDisplay(viewModel: TrackTableViewCellViewModel) {
        if (!equalizer.isHidden) {
            if (viewModel.isPlaying) {
                equalizer.startAnimating()
            } else {
                equalizer.pause()
            }
        }
    }
        
    func setup(viewModel: TrackTableViewCellViewModel, actionCallback:  @escaping ActionCallback) {

        self.viewModelId = viewModel.id
        if viewModel.isCurrentInPlayer && viewModel.isPlayable {
            equalizer.isHidden = false
            equalizerWidthConstraint.constant = 18
            equalizerLeadingConstraint.constant = 15
        } else {
            equalizer.isHidden = true
            equalizerWidthConstraint.constant = 0
            equalizerLeadingConstraint.constant = 0
        }


        self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if viewModel.isPlayable == false {
            self.actionButtonContainerView.isHidden = true
            self.actionButtonConatinerViewTrailingConstraint.constant = -self.actionButtonContainerViewWidthConstraint.constant

            let commingSoonLabel = UILabel()
            commingSoonLabel.text = NSLocalizedString("Comming soon!", comment: "Comming soon text")
            commingSoonLabel.textColor = #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1)
            self.stackView.addArrangedSubview(commingSoonLabel)

        } else {
            self.actionButtonConatinerViewTrailingConstraint.constant = 0
            self.actionButtonContainerView.isHidden = false
        }

        if self.stackView.subviews.isEmpty {
            self.stackViewWidthConstraint.isActive = true
        } else {
            self.stackViewWidthConstraint.isActive = false
        }

        self.titleLabel.text = viewModel.title
        self.descriptionLabel.text = viewModel.description

        self.actionCallback = actionCallback
    }

    // MARK: - Actions -

    @IBAction func onActionButton(sender: UIButton) {
        actionCallback?(.showFoliaActions)
    }
}
