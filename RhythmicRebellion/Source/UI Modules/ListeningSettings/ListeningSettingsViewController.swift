//
//  ListeningSettingsViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/23/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class ListeningSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var refreshControl: UIRefreshControl!
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Public properties -

    private(set) var viewModel: ListeningSettingsViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: ListeningSettingsViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

//        let refreshControl = UIRefreshControl()
//
//        IRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
//        [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
//        [self.myTableView addSubview:refreshControl];

        self.tableView.addSubview(self.refreshControl)
        self.tableView.register(UINib(nibName: "SwitchableTableSectionHeaderView", bundle: nil),
                                forHeaderFooterViewReuseIdentifier: SwitchableTableSectionHeaderView.reuseIdentifier)
        self.tableView.tableFooterView = UIView()

        viewModel.load(with: self)
    }

    // MARK: - Actions

    @IBAction func onRefresh(sender: UIRefreshControl) {
        self.viewModel.reload()
    }

    @IBAction func onSave(sender: Any) {
        self.viewModel.save()
    }

    // MARK: - UITableViewDataSource

    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.listeningSettingsSections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard self.viewModel.listeningSettingsSections.count > section else { return 0 }

        return self.viewModel.listeningSettingsSections[section].items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let tableViewCell: UITableViewCell

        let listeningSettingsSection = self.viewModel.listeningSettingsSections[indexPath.section]
        let listeningSettingsSectionItem = listeningSettingsSection.items[indexPath.row]

        switch listeningSettingsSectionItem {
        case .isDate(let listeningSettingsIsDateSectionItemViewModel):
            let switchableTableViewCell = tableView.dequeueReusableCell(withIdentifier: SwitchableTableViewCell.reuseIdentifier, for: indexPath) as! SwitchableTableViewCell
            switchableTableViewCell.setup(with: listeningSettingsIsDateSectionItemViewModel)
            tableViewCell = switchableTableViewCell
        case .date(let listeningSettingsDateSectionItemViewModel):
            let datePickerTableVieCell = tableView.dequeueReusableCell(withIdentifier: DatePickerTableVieCell.reuseIdentifier, for: indexPath) as! DatePickerTableVieCell
            datePickerTableVieCell.setup(with: listeningSettingsDateSectionItemViewModel)
            tableViewCell = datePickerTableVieCell

        }

        return tableViewCell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let sectionHeaderView = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: SwitchableTableSectionHeaderView.reuseIdentifier)
        let lesteningSectionViewModel = self.viewModel.listeningSettingsSections[section]

        if let switchableTableSectionHeaderView = sectionHeaderView as? SwitchableTableSectionHeaderView {
            switchableTableSectionHeaderView.setup(with: lesteningSectionViewModel)
        }

        return sectionHeaderView
    }
}

// MARK: - Router -
extension ListeningSettingsViewController {

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

extension ListeningSettingsViewController: ListeningSettingsViewModelDelegate {

    func refreshUI() {
        self.saveBarButtonItem.isEnabled = self.viewModel.isDirty
    }

    func reloadUI() {
        self.tableView.reloadData()
        self.refreshControl.endRefreshing()
        self.refreshUI()
    }

    func listeningSettingsSectionsDidBeginUpdate() {
        self.tableView.beginUpdates()
    }

    func listeningSettingsSection(_ listeningSettingsSection: ListeningSettingsSectionViewModel, didInsertItem at: Int) {
        guard let listeningSettingsSectionIndex = self.viewModel.listeningSettingsSections.index(of: listeningSettingsSection) else { return }

        self.tableView.insertRows(at: [IndexPath(row: at, section: listeningSettingsSectionIndex)], with: .automatic)
    }

    func listeningSettingsSection(_ listeningSettingsSection: ListeningSettingsSectionViewModel, didDeleteItem at: Int) {
        guard let listeningSettingsSectionIndex = self.viewModel.listeningSettingsSections.index(of: listeningSettingsSection) else { return }

        self.tableView.deleteRows(at: [IndexPath(row: at, section: listeningSettingsSectionIndex)], with: .automatic)
    }

    func listeningSettingsSectionsDidEndUpdate() {
        self.tableView.endUpdates()
    }

    func show(error: Error) {

        let errorAlertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        errorAlertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Title for AlertAction"), style: .cancel, handler: { (action) in
            errorAlertController.dismiss(animated: true, completion: nil)
        }))

        self.present(errorAlertController, animated: true, completion: nil)
    }

}
