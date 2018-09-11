//
//  ProfileViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class ProfileViewController: UIViewController {

    @IBOutlet weak var profileHeaderView: UIView!
    @IBOutlet weak var profileFooterView: UIView!

    @IBOutlet weak var imageView: RoundedImageView!
    @IBOutlet weak var nameLabel: UILabel!

    @IBOutlet weak var tableView: UITableView!

    // MARK: - Public properties -

    private(set) var viewModel: ProfileViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: ProfileViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.imageView.image = self.imageView.image?.withRenderingMode(.alwaysTemplate)

        self.tableView.backgroundView = UIView()
        self.tableView.backgroundView?.backgroundColor = #colorLiteral(red: 0.04402898997, green: 0.1072343066, blue: 0.2928951979, alpha: 1)
        self.tableView.tableHeaderView = profileHeaderView
        self.tableView.tableFooterView = profileFooterView

        viewModel.load(with: self)
    }

    // MARK: - Actions

    @IBAction func onLogout(sender: Any) {
        self.viewModel.logout()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate -
extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfItems(in: section)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let profileItemTableViewCell = ProfileItemTableViewCell.reusableCell(in: tableView, at: indexPath)
        let profileItemTableViewCellViewModel = self.viewModel.object(at: indexPath)!

        profileItemTableViewCell.setup(viewModel: profileItemTableViewCellViewModel)

        return profileItemTableViewCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectObject(at: indexPath)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
}

// MARK: - Router -
extension ProfileViewController {

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

extension ProfileViewController: ProfileViewModelDelegate {

    func refreshUI() {
        self.nameLabel.text = self.viewModel.userName
    }

    func reloadUI() {
        self.tableView.reloadData()
        self.refreshUI()
    }
}
