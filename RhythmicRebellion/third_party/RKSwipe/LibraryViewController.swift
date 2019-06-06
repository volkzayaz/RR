//
//  LibraryViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

class LibraryViewController: RKSwipeBetweenViewControllers {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let x = R.storyboard.main.vc1()
        let y = R.storyboard.main.vc2()
        
        viewControllerArray.addObjects(from: [x,y])
        
        buttonText = ["My playlists", "Following"]
        
    }
    
    
    
}
