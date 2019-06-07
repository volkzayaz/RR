//
//  RootViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/23/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

class RootViewController: UIViewController, MVVM_View {
    
    var viewModel: RootViewModel!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    @IBOutlet weak var progressConstraint: NSLayoutConstraint!
    @IBOutlet weak var followButton: UIButton!

    @IBOutlet var attributesStackView: UIStackView!
    @IBOutlet var previewTimesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.progressFraction
            .drive(onNext: { [unowned self] (x) in
                self.progressConstraint = self.progressConstraint.setMultiplier(multiplier: x)
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.title.drive(nameLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.artist.drive(artistLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.isArtistFollowed
            .map { $0 ? R.image.follow() : R.image.follow_inactive() }
            .drive(followButton.rx.image(for: .normal))
            .disposed(by: rx.disposeBag)
        
        viewModel.attributes
            .drive(onNext: { [unowned self] x in
                
                self.attributesStackView.subviews.forEach { $0.removeFromSuperview() }
                
                x.forEach { x in
                    
                    switch x {
                        
                    case .downloadEnabled:
                        self.attributesStackView.addArrangedSubview(UIImageView(image: R.image.download_icon()))
                        
                    case .explicitMaterial:
                        self.attributesStackView.addArrangedSubview(UIImageView(image: R.image.explicit()))
                        
                    case .raw(let str):
                        self.previewTimesLabel.text = str
                        self.attributesStackView.addArrangedSubview(self.previewTimesLabel)
                        
                    }
                    
                }
                
            })
            .disposed(by: rx.disposeBag)
        
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        
        if (motion == .motionShake)
        {
            UIAlertView(title: "Info", message: "Current Environent: \(SettingsStore.environment.value)"
                , delegate: nil, cancelButtonTitle: "Ok").show()
        }
        
    }
    
}

extension RootViewController {
    
    @IBAction func presentVideo(_ sender: Any) {
        viewModel.presentVideo()
    }
    
    @IBAction func presentLyrics(_ sender: Any) {
        viewModel.presentLyrics()
    }
    
    @IBAction func presentPromo(_ sender: Any) {
        viewModel.presentPromo()
    }
    
    @IBAction func presentPlaying(_ sender: Any) {
        viewModel.presentPlaying()
    }
    
    @IBAction func presentPlayer(_ sender: Any) {
        viewModel.presentPlayer()
    }
       
}
