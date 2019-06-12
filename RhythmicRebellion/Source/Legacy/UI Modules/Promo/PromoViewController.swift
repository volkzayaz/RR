//
//  PromoViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import AlamofireImage

final class PromoViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var artistNameLabel: UILabel!
    
    @IBOutlet weak var artistSiteButton: UIButton!

    @IBOutlet weak var silenceBIOandCommentarySwitch: UISwitch!
    @IBOutlet weak var silenceBIOandCommentarySwitchTapGestureRecognizer: UITapGestureRecognizer!

    @IBOutlet weak var infoTextView: UILabel!

    @IBOutlet weak var writerNameLabel: UILabel!
    @IBOutlet weak var writerSiteButton: UIButton!

    // MARK: - Public properties -

    var viewModel: PromoViewModel!

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.isAddonsSkipped
            .drive(silenceBIOandCommentarySwitch.rx.isOn)
            .disposed(by: rx.disposeBag)
        
        viewModel.canToggleSkipAddons
            .drive(silenceBIOandCommentarySwitch.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.canToggleSkipAddons
            .map { !$0 }
            .drive(onNext: { [unowned self] (x) in
                self.silenceBIOandCommentarySwitchTapGestureRecognizer.isEnabled = x
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.artistName
            .drive(artistNameLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        //        viewModel.trackName
        //            .drive(trackNameLabel.rx.text)
        //            .disposed(by: rx.disposeBag)
        
        viewModel.infoText
            .drive(infoTextView.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.writerName
            .drive(writerNameLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.canVisitArtistSite
            .drive(onNext: { [unowned self] (x) in
                self.artistSiteButton.isEnabled = x
                self.artistSiteButton.backgroundColor = x ? UIColor(fromHex: 0x007AFF) : UIColor(fromHex: 0x8E888B)
                self.artistSiteButton.alpha = x ? 1 : 0.7
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.canVisitWriterSite
            .drive(onNext: { [unowned self] (x) in
                self.writerSiteButton.isEnabled = x
                self.writerSiteButton.backgroundColor = x ? UIColor(fromHex: 0x007AFF) : UIColor(fromHex: 0x8E888B)
                self.writerSiteButton.alpha = x ? 1 : 0.7
            })
            .disposed(by: rx.disposeBag)
        
        ImageRetreiver.imageForURLWithoutProgress(url: viewModel.thumbnailURL()?.absoluteString ?? "")
            .drive(imageView.rx.image)
            .disposed(by: rx.disposeBag)
        
    }
    


    // MARK: - Actions -
    @IBAction func onArtistSite(sender: Any?) {
        self.viewModel.visitArtistSite()
    }

    @IBAction func onWriterSite(sender: Any?) {
        self.viewModel.visitWriterSite()
    }

    @IBAction func handleSilenceBIOandCommentarySwitchTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        //self.viewModel.routeToAuthorization()
    }

    @IBAction func onToggleSilenceBIOandCommentary(sender: UISwitch) {
        self.viewModel.setSkipAddons(skip: sender.isOn)
    }
}
