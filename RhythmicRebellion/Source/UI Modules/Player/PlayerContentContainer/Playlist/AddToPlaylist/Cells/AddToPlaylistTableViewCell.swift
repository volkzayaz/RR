//
//  AddToPlaylistTableViewCell.swift
//  RhythmicRebellion
//
//  Created by Petro on 8/15/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class AddToPlaylistTableViewCell: UITableViewCell {

    @IBOutlet weak var playlistThumbnail: UIImageView!
    @IBOutlet weak var playlistTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
