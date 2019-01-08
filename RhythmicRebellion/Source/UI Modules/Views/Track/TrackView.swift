//
//  TrackItemTableViewCell.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import DownloadButton
import SnapKit

import RxSwift
import RxCocoa

enum TrackDownloadState {
    case disable
    case ready
    case downloading(TrackAudioFileDownloadingInfo)
    case downloaded
}

class TrackView: UIView {

    typealias ActionCallback = (Actions) -> Void

    enum Actions {
        case showActions
        case download
        case cancelDownloading
        case openIn(CGRect, UIView)
        case showHint(UIView, String)
    }

    @IBOutlet weak var equalizer: EqualizerView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    @IBOutlet weak var actionButtonContainerView: UIView!
    @IBOutlet weak var actionButtonContainerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionButtonConatinerViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var actionActivityIndicatorView: UIActivityIndicatorView!

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

    @IBOutlet weak var equalizerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var equalizerWidthConstraint: NSLayoutConstraint!
    
    var viewModel: TrackViewModel!

    var backwardCompatibilityViewModel: ArtistViewModel?
    var indexPath: IndexPath?
    
    var actionCallback: ActionCallback?
    weak var downloadingInfo: TrackAudioFileDownloadingInfo?

    var disposeBag = DisposeBag()
    
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

    func prepareToDisplay() {
        if (!equalizer.isHidden) {
            if (viewModel.isPlaying) {
                equalizer.startAnimating()
            } else {
                equalizer.pause()
            }
        }

        if self.downloadButton.state == .pending {
            self.downloadButton.pendingView.startSpin()
        }


    }

    func prepareToEndDisplay() {
        self.equalizer.pause()

        disposeBag = DisposeBag()
    }

        
    func setup(viewModel: TrackViewModel, actionCallback:  @escaping ActionCallback) {

        self.downloadingInfo = nil
        
        self.downloadButton.state = .startDownload

        self.viewModel = viewModel
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
        self.downloadButton.state = .startDownload

        self.actionButton.isHidden = false
        self.actionActivityIndicatorView.stopAnimating()

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

            if viewModel.isLockedForActions {
                self.actionButton.isHidden = true
                self.actionActivityIndicatorView.startAnimating()
            }

            if viewModel.isCensorship {
                self.stackView.addArrangedSubview(self.censorshipMarkButton)
            }

            if let downloadState = viewModel.downloadState {

                self.stackView.addArrangedSubview(self.downloadButton)

                switch downloadState {
                case .disable:
                    self.isDownloadAllowed = false
                    self.downloadButton.startDownloadButton.setImage(UIImage(named: "Follow")?.withRenderingMode(.alwaysTemplate), for: .normal)
                    self.downloadButton.startDownloadButton.tintColor = #colorLiteral(red: 0.7450980392, green: 0.7843137255, blue: 1, alpha: 0.95)
//                    self.downloadButton.state = .startDownload
                case .ready:
                    self.isDownloadAllowed = true
//                    self.downloadButton.state = .startDownload
                    self.downloadButton.startDownloadButton.setImage(UIImage(named: "Download")?.withRenderingMode(.alwaysTemplate), for: .normal)
                    self.downloadButton.startDownloadButton.tintColor = #colorLiteral(red: 1, green: 0.3639442921, blue: 0.7127844095, alpha: 1)
                case .downloading(let downloadingInfo):
                    self.isDownloadAllowed = true
                    self.downloadButton.startDownloadButton.setImage(UIImage(named: "Download")?.withRenderingMode(.alwaysTemplate), for: .normal)
                    self.downloadButton.startDownloadButton.tintColor = #colorLiteral(red: 1, green: 0.3639442921, blue: 0.7127844095, alpha: 1)
                    self.downloadButton.state = downloadingInfo.progress.fractionCompleted == 0.0 ? .pending : .downloading
                    self.downloadingInfo = downloadingInfo

                case .downloaded:
                    self.isDownloadAllowed = true
                    self.downloadButton.startDownloadButton.setImage(UIImage(named: "Download")?.withRenderingMode(.alwaysTemplate), for: .normal)
                    self.downloadButton.startDownloadButton.tintColor = #colorLiteral(red: 1, green: 0.3639442921, blue: 0.7127844095, alpha: 1)
                    self.downloadButton.downloadedButton.setImage(UIImage(named: "OpenIn")?.withRenderingMode(.alwaysTemplate), for: .normal)
                    self.downloadButton.state = .downloaded
                }

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
        
        viewModel.downloadPercent
            .drive(onNext: { [weak d = downloadButton] (x) in
                
                d?.state = .downloading
                
                d?.stopDownloadButton.progress = x
                
            })
            .disposed(by: rx.disposeBag)

        //downloadButton.state = .downloading
        
    }

    // MARK: - Actions -

    @IBAction func onActionButton(sender: UIButton) {
        actionCallback?(.showActions)
        
        if let x = indexPath {
            backwardCompatibilityViewModel?.optionsSelected(for: x,
                                                            sourceRect: sender.frame,
                                                            sourceView: actionButtonContainerView)
        }
        
        
    }

    @IBAction func onCensorshipMarkButton(_ sender: UIButton) {
        guard let censorshipMarkButtonHintText = self.censorshipMarkButtonHintText, censorshipMarkButtonHintText.isEmpty == false else { return }
        actionCallback?(.showHint(sender, censorshipMarkButtonHintText))
        
        backwardCompatibilityViewModel?.showTip(tip: censorshipMarkButtonHintText,
                                                view: sender, superView: self)
    }

    @IBAction func onPreviewOptionButton(_ sender: UIButton) {
        guard let previewOptionsButtonHintText = self.previewOptionsButtonHintText, previewOptionsButtonHintText.isEmpty == false else { return }

        actionCallback?(.showHint(sender, previewOptionsButtonHintText))
        
        backwardCompatibilityViewModel?.showTip(tip: previewOptionsButtonHintText,
                                                view: sender, superView: self)
    }
}


extension TrackView: PKDownloadButtonDelegate {

    func downloadButtonTapped(_ downloadButton: PKDownloadButton!, currentState state: PKDownloadButtonState) {

        guard self.isDownloadAllowed == true else {
            guard let downloadButtonHintText = self.downloadButtonHintText, downloadButtonHintText.isEmpty == false else { return }
            actionCallback?(.showHint(downloadButton, downloadButtonHintText))
            
            backwardCompatibilityViewModel?.showTip(tip: downloadButtonHintText,
                                                    view: downloadButton, superView: self)
            
            return
        }

        switch state {
        case .startDownload:
            actionCallback?(.download)

            viewModel.download()
            
//            if let x = indexPath {
//                //backwardCompatibilityViewModel?.tracksViewModel.downloadObject(at: x)
//            }
            
        case .pending, .downloading:
            actionCallback?(.cancelDownloading)
            
            viewModel.cancelDownload()
//            if let x = indexPath {
//                //backwardCompatibilityViewModel?.tracksViewModel.cancelDownloadingObject(at: x)
//            }
            
        case .downloaded:
            actionCallback?(.openIn(downloadButton.frame, self.stackView))
        }
    }

}
