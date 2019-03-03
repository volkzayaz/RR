//
//  ViewController+ErrorMessage.swift
//   
//
//  Created by Vlad Soroka on 2/26/16.
//  Copyright © 2016   All rights reserved.
//

import UIKit

typealias MessageCallback = () -> Void

extension UIViewController {
    
    func showInfoMessage(withTitle title:String,
                         _ text: String,
                         _ buttonText: String = "Ok" ,
                         _ callback: MessageCallback? = nil) {
        let alertController = UIAlertController(title: title, message: text, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: buttonText, style: .default) { _ in
            if let callback = callback {
                callback()
            }
        })
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showSimpleQuestionMessage(withTitle title:String,
                                   _ question: String,
                                   negativeText: String = "No",
                                   positiveText: String = "Yes",
                                   _ positiveCallback: MessageCallback? = nil,
                                   _ negativeCallback: MessageCallback? = nil)
    {
        let alertController = UIAlertController(title: title, message: question, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: negativeText, style: .cancel) { _ in
            if let callback = negativeCallback {
                callback()
            }
        })
        
        alertController.addAction(UIAlertAction(title: positiveText, style: .default) { _ in
            if let callback = positiveCallback {
                callback()
            }
        })
        
        self.present(alertController, animated: true, completion: nil)

    }
    
    func showOptions(with title: String,
                        options: [String],
                        style: UIAlertController.Style = .alert,
                        positiveCallback: ( (Int) -> () )? = nil,
                        negativeCallback: MessageCallback? = nil)
    {
        let alertController = UIAlertController(title: title,
                                                message: "",
                                                preferredStyle: style)
        
        options.enumerated().forEach { (offset: Int, element: String) in
            
            alertController.addAction(UIAlertAction(title: element, style: .default) { _ in
                positiveCallback?(offset)
            })
            
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            negativeCallback?()
        })
        
        alertController.popoverPresentationController?.sourceView = self.view
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
}
