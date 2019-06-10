//
//  UIViewController+Embeded.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

extension UIViewController {
    
    func embededIntoNavigation() -> UIViewController {
        
        let nav = R.storyboard.main.eyeBrowNavigation()!
        nav.viewControllers = [self]
        
        let closeButton = UIBarButtonItem(title: "Close",
                                          style: .plain,
                                          target: self, action: "dismissController")
        closeButton.tintColor = UIColor(fromHex: 0xBFC7FF)
        
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        nav.navigationBar.titleTextAttributes = textAttributes
        
        self.navigationItem.leftBarButtonItem = closeButton
        
        return nav
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: {
        })
    }
    
}