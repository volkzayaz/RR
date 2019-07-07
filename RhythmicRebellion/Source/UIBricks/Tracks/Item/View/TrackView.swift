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

import SwiftyGif

class TrackView: UIView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!
    
    @IBOutlet weak var equlizerView: UIView!
    @IBOutlet weak var equalizerImageView: UIImageView!
    
    @IBOutlet weak var attributesStackView: UIStackView!
    @IBOutlet var previewLabel: UILabel!
    
    @IBOutlet weak var optionsButton: UIButton!
    
    var viewModel: TrackViewModel!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        equalizerImageView.setGifImage( try! UIImage(gifName: "equalizer.gif") )
        equalizerImageView.stopAnimatingGif()
    }
    
    func prepareToDisplay() {
        artworkImageView.image = nil
    }

    func prepareToEndDisplay() {
        disposeBag = DisposeBag()
    }

    func setup(viewModel: TrackViewModel) {

        self.viewModel = viewModel
      
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description
        equlizerView.backgroundColor = viewModel.equalizerBackgroundColor
        
        indexLabel.isHidden = viewModel.indexHidden
        artworkImageView.isHidden = viewModel.artworkHidden
        
        viewModel.equalizerHidden
            .drive(onNext: { [unowned self] (isHidden) in
                
                self.equlizerView.isHidden = isHidden
                
                if self.viewModel.artworkHidden {
                    self.indexLabel.isHidden = !isHidden
                }
                
            })
            .disposed(by: disposeBag)
        
        viewModel.isPlaying
            .drive(onNext: { [unowned self] (isPlaying) in
                isPlaying ?
                    self.equalizerImageView.startAnimatingGif() :
                    self.equalizerImageView.stopAnimatingGif()
            })
            .disposed(by: rx.disposeBag)
        
        indexLabel.text = viewModel.index
        ImageRetreiver.imageForURLWithoutProgress(url: viewModel.artwork)
            .drive(artworkImageView.rx.image)
            .disposed(by: disposeBag)
        
        viewModel.attributes
            .drive(onNext: { [unowned self] x in
                
                self.attributesStackView.subviews.forEach { $0.removeFromSuperview() }
                
                x.forEach { x in
                    
                    switch x {
                        
                    case .downloadEnabled:
                        self.attributesStackView.addArrangedSubview(UIImageView(image: R.image.download_icon()))
                        
                    case .explicitMaterial:
                        self.attributesStackView.addArrangedSubview(UIImageView(image: R.image.explicit()))
                        
                    case .exclaimation:
                        self.attributesStackView.addArrangedSubview(UIImageView(image: R.image.exclaim()))
                        
                    case .lock:
                        self.attributesStackView.addArrangedSubview(UIImageView(image: R.image.lock()))
                        
                        
                    case .raw(let str):
                        self.previewLabel.text = str
                        self.attributesStackView.addArrangedSubview(self.previewLabel)
                        
                    }
                    
                }
                
            })
            .disposed(by: disposeBag)
        
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
