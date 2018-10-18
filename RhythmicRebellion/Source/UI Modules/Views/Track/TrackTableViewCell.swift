//
//  TrackItemTableViewCell.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import DownloadButton


enum TrackDownloadState {
    case disable
    case ready
    case downloading(Progress)
    case downloaded
}

protocol TrackTableViewCellViewModel {

    var id: String { get }

    var title: String { get }
    var description: String { get }

    var isPlayable: Bool { get }

    var isCurrentInPlayer: Bool { get }
    var isPlaying: Bool { get }

    var isCensorship: Bool { get }
    var censorshipHintText: String? { get }

    var previewOptionImage: UIImage? { get }
    var previewOptionHintText: String? { get }

    var downloadState: TrackDownloadState? { get }
    var downloadHintText: String? { get }
}

class TrackTableViewCell: UITableViewCell, CellIdentifiable {

    typealias ActionCallback = (Actions) -> Void

    enum Actions {
        case showActions
        case download
        case cancelDownloading
        case openIn
        case showHint(UIView, String)
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

    @IBOutlet var censorshipMarkButton: UIButton!
    @IBOutlet var previewOptionsButton: UIButton!
    @IBOutlet var downloadButton: PKDownloadButton!

    var censorshipMarkButtonHintText: String?
    var previewOptionsButtonHintText: String?
    var downloadButtonHintText: String?

    var isDownloadAllowed: Bool = false
    var progressObserver: NSKeyValueObservation?


    @IBOutlet weak var equalizerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var equalizerWidthConstraint: NSLayoutConstraint!
    
    var viewModelId: String = ""

    var actionCallback: ActionCallback?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.censorshipMarkButton.setImage(self.censorshipMarkButton.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)

        self.previewOptionsButton.layer.borderWidth = 0.65
        self.previewOptionsButton.layer.borderColor = #colorLiteral(red: 0.7450980392, green: 0.7843137255, blue: 1, alpha: 0.95)

        self.downloadButton.delegate = self
        self.downloadButton.startDownloadButton.cleanDefaultAppearance()
        self.downloadButton.startDownloadButton.tintColor = #colorLiteral(red: 0.7450980392, green: 0.7843137255, blue: 1, alpha: 0.95)
        self.downloadButton.stopDownloadButton.tintColor = #colorLiteral(red: 0.7450980392, green: 0.7843137255, blue: 1, alpha: 0.95)
        self.downloadButton.downloadedButton.cleanDefaultAppearance()
        self.downloadButton.downloadedButton.tintColor = #colorLiteral(red: 0.7450980392, green: 0.7843137255, blue: 1, alpha: 0.95)
    }

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

        self.progressObserver = nil
        self.downloadButton.state = .startDownload

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

            let comingSoonLabel = UILabel()
            comingSoonLabel.text = NSLocalizedString("Coming soon!", comment: "Coming soon text")
            comingSoonLabel.textColor = #colorLiteral(red: 0.7450980392, green: 0.7843137255, blue: 1, alpha: 1)
            self.stackView.addArrangedSubview(comingSoonLabel)

        } else {
            self.actionButtonConatinerViewTrailingConstraint.constant = 0
            self.actionButtonContainerView.isHidden = false


            if viewModel.isCensorship {
                self.stackView.addArrangedSubview(self.censorshipMarkButton)
            }

            if let downloadState = viewModel.downloadState {
                switch downloadState {
                case .disable:
                    self.isDownloadAllowed = false
                    self.downloadButton.startDownloadButton.setImage(UIImage(named: "Follow")?.withRenderingMode(.alwaysTemplate), for: .normal)
                    self.downloadButton.state = .startDownload
                case .ready:
                    self.isDownloadAllowed = true
                    self.downloadButton.startDownloadButton.setImage(UIImage(named: "Download")?.withRenderingMode(.alwaysTemplate), for: .normal)
                case .downloading(let progress):
                    self.isDownloadAllowed = true
                    self.downloadButton.startDownloadButton.setImage(UIImage(named: "Download")?.withRenderingMode(.alwaysTemplate), for: .normal)
                    self.downloadButton.state = .downloading

                    self.progressObserver = progress.observe(\.fractionCompleted) { (pobject, _) in
                        let value = pobject.fractionCompleted
                        DispatchQueue.main.async {
                            self.downloadButton.stopDownloadButton.progress = CGFloat(value)
                        }
                    }
                case .downloaded:
                    self.isDownloadAllowed = true
                    self.downloadButton.startDownloadButton.setImage(UIImage(named: "Download")?.withRenderingMode(.alwaysTemplate), for: .normal)
                    self.downloadButton.downloadedButton.setImage(UIImage(named: "OpenIn")?.withRenderingMode(.alwaysTemplate), for: .normal)
                    self.downloadButton.state = .downloaded
                }

                self.stackView.addArrangedSubview(self.downloadButton)
            } else {
                self.isDownloadAllowed = false
            }

            self.previewOptionsButton.setImage(viewModel.previewOptionImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            self.stackView.addArrangedSubview(self.previewOptionsButton)
        }

        if self.stackView.subviews.isEmpty {
            self.stackViewWidthConstraint.isActive = true
        } else {
            self.stackViewWidthConstraint.isActive = false
        }

        self.titleLabel.text = viewModel.title
        self.descriptionLabel.text = viewModel.description

        self.censorshipMarkButtonHintText = viewModel.censorshipHintText
        self.previewOptionsButtonHintText = viewModel.previewOptionHintText
        self.downloadButtonHintText = viewModel.downloadHintText

        self.actionCallback = actionCallback
    }

    // MARK: - Actions -

    @IBAction func onActionButton(sender: UIButton) {
        actionCallback?(.showActions)
    }

    @IBAction func onCensorshipMarkButton(sender: UIButton) {
        guard let censorshipMarkButtonHintText = self.censorshipMarkButtonHintText, censorshipMarkButtonHintText.isEmpty == false else { return }
        actionCallback?(.showHint(sender, censorshipMarkButtonHintText))
    }

    @IBAction func onPreviewOptionsButton(sender: UIButton) {
        guard let previewOptionsButtonHintText = self.previewOptionsButtonHintText, previewOptionsButtonHintText.isEmpty == false else { return }

        actionCallback?(.showHint(sender, previewOptionsButtonHintText))
    }
}


extension TrackTableViewCell: PKDownloadButtonDelegate {

    func downloadButtonTapped(_ downloadButton: PKDownloadButton!, currentState state: PKDownloadButtonState) {

        guard self.isDownloadAllowed == true else {
            guard let downloadButtonHintText = self.downloadButtonHintText, downloadButtonHintText.isEmpty == false else { return }
            actionCallback?(.showHint(downloadButton, downloadButtonHintText))
            return
        }

        switch state {
        case .startDownload:
            self.downloadButton.state = .pending
            actionCallback?(.download)
        case .pending:
            break
        case .downloading:
            self.downloadButton.state = .startDownload
            actionCallback?(.cancelDownloading)
        case .downloaded:
            actionCallback?(.openIn)
        }
    }

}
