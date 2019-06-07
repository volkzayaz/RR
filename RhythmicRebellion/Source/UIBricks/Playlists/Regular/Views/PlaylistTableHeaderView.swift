//
//  PlaylistTableViewHeader.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import AlamofireImage
import DownloadButton

class PlaylistTableHeaderView: UIView {
    
    @IBOutlet weak var actionButton: UIButton!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet var downloadButton: PKDownloadButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        actionButton.layer.borderWidth = 1
        actionButton.layer.borderColor = UIColor.white.cgColor
    }
    
    func setup(viewModel: PlaylistHeaderViewModel) {

        self.titleLabel.text = viewModel.title
        self.descriptionLabel.text = viewModel.description

        ImageRetreiver.imageForURLWithoutProgress(url: viewModel.thumbnailURL?.absoluteString ?? "")
            .map { $0 ?? R.image.cover_placeholder() }
            .drive(imageView.rx.image)
            .disposed(by: rx.disposeBag)
        
        self.downloadButton.startDownloadButton.setImage(UIImage(named: "Download")?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.downloadButton.startDownloadButton.tintColor = #colorLiteral(red: 1, green: 0.3639442921, blue: 0.7127844095, alpha: 1)
        self.downloadButton.downloadedButton.setImage(UIImage(named: "OpenIn")?.withRenderingMode(.alwaysTemplate), for: .normal)
        
        self.downloadButton.startDownloadButton.cleanDefaultAppearance()
        self.downloadButton.startDownloadButton.tintColor = #colorLiteral(red: 0.7450980392, green: 0.7843137255, blue: 1, alpha: 0.95)
        self.downloadButton.stopDownloadButton.tintColor = #colorLiteral(red: 0.7450980392, green: 0.7843137255, blue: 1, alpha: 0.95)
        self.downloadButton.downloadedButton.cleanDefaultAppearance()
        self.downloadButton.downloadedButton.tintColor = #colorLiteral(red: 0.7450980392, green: 0.7843137255, blue: 1, alpha: 0.95)
    }

}
