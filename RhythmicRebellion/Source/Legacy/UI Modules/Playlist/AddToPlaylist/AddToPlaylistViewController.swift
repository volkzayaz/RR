//
//  AddToPlaylistViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

import RxDataSources

class AddToPlaylistViewController: UIViewController, UITableViewDelegate {

    var viewModel: AddToPlaylistViewModel!
    
    lazy var dataSource = RxTableViewSectionedAnimatedDataSource<AnimatableSectionModel<String, AddToPlaylistViewModel.Row>>(configureCell: { [unowned self] (_, tableView, ip, data) in
        
        switch data {
            
        case .create:
        
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.addPlaylistCellId,
                                                     for: ip)!
            cell.viewModel = self.viewModel
            
            return cell
            
        case .playlist(let x):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.playlistCellId,
                                                     for: ip)!
            cell.playlistTitle.text = x.name
            
            return cell
        }
        
    })

    @IBOutlet weak var tableView: UITableView!

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
        
        viewModel.dataSource
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        tableView.rx.modelSelected(AddToPlaylistViewModel.Row.self)
            .subscribe(onNext: { [unowned self] (x) in
                guard case .playlist(let p) = x else { return }
                
                self.viewModel.select(playlist: p)
            })
            .disposed(by: rx.disposeBag)
        
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        viewModel.cancel()        
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) as? CreatePlaylistTableViewCell {
            cell.playlistNametextField.becomeFirstResponder()
        }
        
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
