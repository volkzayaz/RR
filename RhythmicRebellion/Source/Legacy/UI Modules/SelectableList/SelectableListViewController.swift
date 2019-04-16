//
//  SelectableListViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/31/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class SelectableListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var refreshControl: UIRefreshControl!
    
    // MARK: - Public properties -
    private var searchController: UISearchController?

    private(set) var viewModel: SelectableListViewModel!
    private(set) var router: FlowRouter!

    private var keyboardWillShowObserver: NSObjectProtocol?
    private var keyboardWillHideObserver: NSObjectProtocol?

    // MARK: - Configuration -

    func configure(viewModel: SelectableListViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    deinit {

//        self.tableView.tableHeaderView = nil

        if let keyboardWillShowObserver = self.keyboardWillShowObserver {
            NotificationCenter.default.removeObserver(keyboardWillShowObserver)
            self.keyboardWillShowObserver = nil
        }

        if let keyboardWillHideObserver = self.keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(keyboardWillHideObserver)
            self.keyboardWillHideObserver = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = self.viewModel.title

        self.tableView.backgroundView = UIView()
        self.tableView.backgroundColor = #colorLiteral(red: 0.0431372549, green: 0.07450980392, blue: 0.2274509804, alpha: 1)

        if self.viewModel.isSearchable {
            self.setupSearchController()
        }

        self.tableView.tableFooterView = UIView()
        self.tableView.addSubview(self.refreshControl)

        if viewModel.selectionType == .multiple {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: viewModel.doneButtonTitle, style: .done, target: self, action: #selector(onDone(sender:)))
        }

        viewModel.load(with: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.keyboardWillShowObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in
            self.keyboardDidShow(notification: notification)
        }

        self.keyboardWillHideObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in
            self.keyboardWillHide(notification: notification)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if let keyboardWillShowObserver = self.keyboardWillShowObserver {
            NotificationCenter.default.removeObserver(keyboardWillShowObserver)
            self.keyboardWillShowObserver = nil
        }

        if let keyboardWillHideObserver = self.keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(keyboardWillHideObserver)
            self.keyboardWillHideObserver = nil
        }
    }

    func setupSearchController() {
        let searchController = UISearchController(searchResultsController: nil)

        self.definesPresentationContext = true

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self

        searchController.searchBar.layer.cornerRadius = 15.0
        searchController.searchBar.layer.masksToBounds = true
        searchController.searchBar.barTintColor = #colorLiteral(red: 0.0431372549, green: 0.07450980392, blue: 0.2274509804, alpha: 1)
        searchController.searchBar.tintColor = #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1)
        searchController.searchBar.backgroundColor = #colorLiteral(red: 0.0431372549, green: 0.07450980392, blue: 0.2274509804, alpha: 1)
        searchController.searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
//        searchController.searchBar.barStyle = .black
//        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.clearsContextBeforeDrawing = true
//        searchController.searchBar.isTranslucent = true

        if let textFieldInsideSearchBar = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textFieldInsideSearchBar.textColor = #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1)
            textFieldInsideSearchBar.backgroundColor = UIColor.white.withAlphaComponent(0.1)

            let placeholder = NSLocalizedString("Search", comment: "Search plaholder")
            let attributedPlaceholder = NSAttributedString(string: textFieldInsideSearchBar.placeholder ?? placeholder,
                                                           attributes: [NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1)])
            textFieldInsideSearchBar.attributedPlaceholder = attributedPlaceholder

            if let imageView = textFieldInsideSearchBar.leftView as? UIImageView {
                imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1)
            }

            if let imageView = textFieldInsideSearchBar.rightView as? UIImageView {
                imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1)
            }
        }

        self.tableView.tableHeaderView = searchController.searchBar
        self.tableView.tableHeaderView?.backgroundColor = #colorLiteral(red: 0.0431372549, green: 0.07450980392, blue: 0.2274509804, alpha: 1)

        self.searchController = searchController
    }

    // MARK: - Actions -

    @IBAction func onRefresh(sender: UIRefreshControl) {
        self.viewModel.reload()
    }

    @IBAction func onDone(sender: Any?) {
        self.viewModel.done()
    }

    // MARK: - Notifications -
    func keyboardDidShow(notification: Notification) {
        guard let keyboardFrameValue: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = self.view.convert(keyboardFrameValue.cgRectValue, from: nil)

        let bottomInset = self.view.bounds.maxY - keyboardFrame.minY
        if bottomInset > 0 {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
            self.tableView.contentInset = contentInsets
            self.tableView.scrollIndicatorInsets = contentInsets
        }
    }

    func keyboardWillHide(notification: Notification) {
        self.tableView.contentInset = .zero
        self.tableView.scrollIndicatorInsets = .zero
    }
}

extension SelectableListViewController: UITableViewDataSource, UITableViewDelegate {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.numberOfSections()
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfItems(in: section)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let selectableListItemViewModel = self.viewModel.object(at: indexPath)!

        switch selectableListItemViewModel {
        case let defaultSelectableListItemViewModel as DefaultSelectableListItemViewModel:
            let selectableListItemTableViewCell = SelectableListItemTableViewCell.reusableCell(in: tableView, at: indexPath)
            selectableListItemTableViewCell.setup(viewModel: defaultSelectableListItemViewModel)
            return selectableListItemTableViewCell


        case let addNewSelectableListItemViewModel as AddNewSelectableListItemViewModel:
            let addNewSelectableListItemTableViewCell = AddNewSelectableListItemTableViewCell.reusableCell(in: tableView, at: indexPath)
            addNewSelectableListItemTableViewCell.setup(viewModel: addNewSelectableListItemViewModel)
            return addNewSelectableListItemTableViewCell

        default: fatalError("Unknown SelectableListItemViewModel!")
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: false)
        self.viewModel.selectObject(at: indexPath)
    }

}

extension SelectableListViewController: UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {
        self.viewModel.filterItems(with: searchController.searchBar.text ?? "")
    }
}


// MARK: - Router -
extension SelectableListViewController {

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

extension SelectableListViewController: SelectableListViewModelDelegate {

    func refreshUI() {
        self.navigationItem.rightBarButtonItem?.isEnabled = self.viewModel.canDone
    }

    func reloadUI() {
        self.tableView.reloadData()
        self.refreshControl.endRefreshing()
        self.refreshUI()
    }

    func reloadItems(at indexPaths: [IndexPath]) {
        self.tableView.reloadRows(at: indexPaths, with: self.viewModel.selectionType == .multiple ? .automatic : .none)

        self.refreshUI()
    }
}
