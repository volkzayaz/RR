//
//  AnimationStatus.swift
//     
//
//  Created by Vlad Soroka on 10/15/16.
//  Copyright © 2016    All rights reserved.
//

import RxSwift

protocol CanChangeAnimationStatus {
    
    func changedAnimationStatusTo(status: Bool)
    
}

extension UIViewController : CanChangeAnimationStatus {
    
    func changedAnimationStatusTo(status: Bool) {
        
        if self.isViewLoaded {
            view.indicateProgress = status
        }
        else {
            let _ =
            rx.sentMessage(#selector(UIViewController.viewDidLoad))
                .subscribe( onNext: { [unowned self] _ in self.view.indicateProgress = status })
        }
        
    }
    
}

extension UIView : CanChangeAnimationStatus {
    
    func changedAnimationStatusTo(status: Bool) {
        
        self.indicateProgress = status
        
    }
    
}
