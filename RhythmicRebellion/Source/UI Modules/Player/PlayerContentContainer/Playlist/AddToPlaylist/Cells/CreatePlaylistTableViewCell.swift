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
    
    var nameEditingFinishedCallback : ((String?)->())?    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        NotificationCenter.default.addObserver(forName: Notification.Name.UITextFieldTextDidEndEditing, object: playlistNametextField, queue: OperationQueue.main) {[weak self] (notification) in
            self?.nameEditingFinishedCallback?(self?.playlistNametextField.text)
        }
        
        playlistNametextField.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }

}
