//
//  PromoViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class PromoViewController: UIViewController {

    // MARK: - Public properties -

    private(set) var viewModel: PromoViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: PromoViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.load(with: self)
    }

    @IBAction func navigateToGoogle() {
        guard let url = URL(string: "http://www.google.com.ua") else { return }
        self.viewModel.navigateToPage(with: url)
    }

    @IBAction func navigateToYoutube() {
        guard let url = URL(string: "https://www.youtube.com") else { return }
        self.viewModel.navigateToPage(with: url)
    }
}

// MARK: - Router -
extension PromoViewController {

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

extension PromoViewController: PromoViewModelDelegate {

    func refreshUI() {

    }

}
