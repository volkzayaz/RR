//
//  AddToPlaylistViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class AddToPlaylistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Public properties -

    @IBOutlet weak var tableView: UITableView!
    var viewModel: AddToPlaylistViewModel!
    
    // MARK: - Configuration -

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.tableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(AddToPlaylistViewController.keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AddToPlaylistViewController.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        viewModel.load(with: self)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        viewModel.cancel()        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfItems()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let vm = self.viewModel.object(at: indexPath)!
        let cell = tableView.dequeueReusableCell(withIdentifier: vm.identifier)!
        vm.configure(cell: cell)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? CreatePlaylistTableViewCell {
            cell.playlistNametextField.becomeFirstResponder()
        }
        self.viewModel.selectObject(at: indexPath)
    }
    
    // MARK: - Notifications
    @objc func keyboardDidShow(notification: Notification) {
        guard let keyboardFrameValue: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = self.view.convert(keyboardFrameValue.cgRectValue, from: nil)
        
        let bottomInset = self.view.bounds.maxY - keyboardFrame.minY
        if bottomInset > 0 {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
            tableView.contentInset = contentInsets
            tableView.scrollIndicatorInsets = contentInsets
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
    }
}

extension AddToPlaylistViewController: AddToPlaylistViewModelDelegate {

    func refreshUI() {

    }

    func reloadUI() {
        tableView.reloadData()
    }

}
