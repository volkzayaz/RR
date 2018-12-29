//
//  LyricsViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class LyricsViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var karaokeModeButton: UIButton!

    // MARK: - Public properties -

    private(set) var viewModel: LyricsViewModelProtocol!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: LyricsViewModelProtocol, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.load(with: self)
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

// MARK: - Router -
extension LyricsViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        router.prepare(for: segue, sender: sender)
        return super.prepare(for: segue, sender: sender)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
            return false
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

}

extension LyricsViewController: LyricsViewModelDelegate {

    func refreshUI() {

        self.textView.text = self.viewModel.infoText.isEmpty ? self.viewModel.lyricsText : self.viewModel.infoText
        self.karaokeModeButton.isEnabled = self.viewModel.canSwitchToKaraokeMode
    }

}
