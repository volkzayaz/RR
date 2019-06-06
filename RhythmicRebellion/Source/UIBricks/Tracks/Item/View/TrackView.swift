//
//  TrackItemTableViewCell.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import SnapKit

import RxSwift
import RxCocoa

class TrackView: UIView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    var viewModel: TrackViewModel!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
    }

    func prepareToDisplay() {
        
    }

    func prepareToEndDisplay() {
        disposeBag = DisposeBag()
    }

    func setup(viewModel: TrackViewModel) {

        self.viewModel = viewModel
      
        self.titleLabel.text = viewModel.title
        self.descriptionLabel.text = viewModel.description

        
//        viewModel.previewOptionHintText
//            .drive(onNext: { [weak self] (t) in
//                self?.previewOptionsButtonHintText = t
//            })
//            .disposed(by: rx.disposeBag)
//            
//        self.downloadButtonHintText = viewModel.downloadHintText
//        
//        viewModel.downloadViewModel?.downloadPercent
//            .drive(onNext: { [weak d = downloadButton] (x) in
//                d?.stopDownloadButton.progress = x
//            })
//            .disposed(by: disposeBag)
//
//        viewModel.downloadViewModel?.state
//            .drive(onNext: { [weak d = downloadButton] (x) in
//                d?.state = x
//            })
//            .disposed(by: disposeBag)
        
//        viewModel.isPlaying
//            .drive(onNext: { [weak e = equalizer] (isPlaying) in
//                isPlaying ?
//                    e?.startAnimating() :
//                    e?.pause()
//            })
//            .disposed(by: disposeBag)
//
    }

    // MARK: - Actions -

    @IBAction func onActionButton(sender: UIButton) {
        
        viewModel.presentActions(sourceRect: sender.frame,
                                 sourceView: self)
        
    }

}


//extension TrackView: PKDownloadButtonDelegate {
//
//    func downloadButtonTapped(_ downloadButton: PKDownloadButton!, currentState state: PKDownloadButtonState) {
//
//        guard viewModel.downloadEnabled else {
//            guard let downloadButtonHintText = self.downloadButtonHintText, downloadButtonHintText.isEmpty == false else { return }
//            
//            viewModel.showTip(tip: downloadButtonHintText,
//                              view: downloadButton, superView: self)
//            
//            return
//        }
//
//        switch state {
//        case .startDownload:
//            viewModel.downloadViewModel?.download()
//            
//        case .pending, .downloading:
//            viewModel.downloadViewModel?.cancelDownload()
//            
//        case .downloaded:
//            viewModel.openIn(sourceRect: downloadButton.frame, sourceView: stackView)
//        }
//    }
//
//}
