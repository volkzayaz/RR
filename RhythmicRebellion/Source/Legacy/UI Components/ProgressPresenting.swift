//
//  ProgressPresenting.swift
//  RhythmicRebellion
//
//  Created by Petro on 8/16/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import MBProgressHUD

protocol ProgressPresenting {
    func showProgress()
    func hideProgress()
}

extension ProgressPresenting where Self: UIViewController {
    func showProgress() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
    }
    
    func hideProgress() {
        MBProgressHUD.hide(for: self.view, animated:  true)
    }
}
