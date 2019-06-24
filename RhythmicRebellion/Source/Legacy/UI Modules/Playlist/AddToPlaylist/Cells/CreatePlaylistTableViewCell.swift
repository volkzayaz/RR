//
//  CreatePlaylistTableViewCell.swift
//  RhythmicRebellion
//
//  Created by Petro on 8/15/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class CreatePlaylistTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var addImage: UIImageView!
    @IBOutlet weak var playlistNametextField: UITextField!
    
    var viewModel: AddToPlaylistViewModel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        NotificationCenter.default.addObserver(forName: UITextField.textDidEndEditingNotification, object: playlistNametextField, queue: OperationQueue.main) {[weak self] (notification) in
            
            guard let t = self?.playlistNametextField.text else { return }
            self?.playlistNametextField.text = ""
            
            self?.viewModel.createPlaylist(with: t)
            
        }
        
        playlistNametextField.delegate = self
        
        addImage.layer.borderColor = UIColor(red: 0.39, green: 0.39, blue: 0.6, alpha: 1.0).cgColor
        addImage.layer.borderWidth = 1
        addImage.layer.cornerRadius = 6
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }

}
