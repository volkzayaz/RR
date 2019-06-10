//
//  LyricsKaraokeContainerViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import RxSwift
import RxCocoa

final class LyricsKaraokeViewController: UIViewController, ContainerViewController {

    @IBOutlet weak var containerView: UIView!

    // MARK: ContainerViewController

    weak var currentViewController: UIViewController?

    // MARK: - Public properties -

    var viewModel: LyricsKaraokeViewModel!
    
    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.load()
    }
    
}

// MARK: - Router -
extension LyricsKaraokeViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        viewModel.router.prepare(for: segue, sender: sender)
        return super.prepare(for: segue, sender: sender)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if viewModel.router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
            return false
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

}


