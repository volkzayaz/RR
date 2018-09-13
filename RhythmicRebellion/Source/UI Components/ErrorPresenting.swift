//
//  ErrorPresenting.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol ErrorPresenting {
    func show(error: Error)
}

extension ErrorPresenting where Self: UIViewController {

    func show(error: Error) {
        let errorAlertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        errorAlertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Title for AlertAction"), style: .cancel, handler: { (action) in
        errorAlertController.dismiss(animated: true, completion: nil)
        }))

        self.present(errorAlertController, animated: true, completion: nil)
    }
}
