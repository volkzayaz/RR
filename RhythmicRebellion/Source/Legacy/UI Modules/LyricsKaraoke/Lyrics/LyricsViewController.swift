//
//  LyricsViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import RxCocoa

final class LyricsViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var karaokeModeButton: UIButton!

    // MARK: - Public properties -

    var viewModel: LyricsViewModel!

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.canSwitchToKaraoke
            .drive(karaokeModeButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.displayText
            .drive(textView.rx.text)
            .disposed(by: rx.disposeBag)
        ///fix for long text jumping up
        textView.isScrollEnabled = false
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        textView.isScrollEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Actions -
    @IBAction func onKaraokeMode(sender: Any) {
        self.viewModel.switchToKaraoke()
    }

}
