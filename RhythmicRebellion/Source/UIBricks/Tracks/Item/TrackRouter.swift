//
//  TrackRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 1/9/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

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
    
    func present(actions: [RRSheet.Action],
                 sourceRect: CGRect, sourceView: UIView) {
    
        owner.show(viewModels: actions, sourceRect: sourceRect, sourceView: sourceView)
        
    }
    
}
