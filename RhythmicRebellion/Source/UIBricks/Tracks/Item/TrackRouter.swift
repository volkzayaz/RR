//
//  TrackRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 1/9/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import EasyTipView

struct TrackRouter : MVVM_Router {
    
    var owner: UIViewController {
        return _owner!
    }
    
    weak private var _owner: TrackRouter.T?
    init(owner: TrackRouter.T) {
        self._owner = owner
    }
    
    func showOpenIn(url: URL, sourceRect: CGRect, sourceView: UIView) {
        
        let activityViewController = UIActivityViewController(activityItems: [url],
                                                              applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceView = sourceView
        activityViewController.popoverPresentationController?.sourceRect = sourceRect
        
        owner.present(activityViewController, animated: true, completion: nil)
    }
    
    func present(actions: AlertActionsViewModel<ActionViewModel>,
                 sourceRect: CGRect, sourceView: UIView) {
    
        let actionSheet = UIAlertController.make(from: actions)
        
        actionSheet.popoverPresentationController?.sourceView = sourceView
        actionSheet.popoverPresentationController?.sourceRect = sourceRect
        
        owner.present(actionSheet, animated: true, completion: nil)
        
    }
    
    func showTip(text: String, view: UIView, superView: UIView) {
        
        let tipView = TipView(text: text, preferences: EasyTipView.globalPreferences)
        tipView.showTouched(forView: view, in: superView)
        
    }
    
    
    
}
