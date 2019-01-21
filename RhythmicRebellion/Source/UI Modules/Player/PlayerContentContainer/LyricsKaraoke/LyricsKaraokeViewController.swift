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

    private(set) var viewModel: LyricsKaraokeViewModelProtocol!
    private(set) var router: FlowRouter!

    let disposeBag = DisposeBag()

    // MARK: - Configuration -

    func configure(viewModel: LyricsKaraokeViewModelProtocol, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.load(with: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.viewModel?.lyricsStateError.notNil().subscribe(onNext: { (error) in
            self.show(error: error)
        })
        .disposed(by: disposeBag)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
}

// MARK: - Router -
extension LyricsKaraokeViewController {

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

extension LyricsKaraokeViewController: LyricsKaraokeViewModelDelegate {

    func refreshUI() {

    }

}

