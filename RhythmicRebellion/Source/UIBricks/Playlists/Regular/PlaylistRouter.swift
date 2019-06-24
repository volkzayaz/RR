//
//  PlaylistRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

struct PlaylistRouter {

    weak var owner: UIViewController!
    init(owner: UIViewController) {
        self.owner = owner
    }
    
    func showAddToPlaylist(for attachable: AttachableProvider) {
        
        let c = R.storyboard.main.addToPlaylistContainer()!
        let x = R.storyboard.main.addToPlaylistViewController()!
        
        x.viewModel = .init(router: .init(owner: x), attachable: attachable)
        
        c.viewControllers = [x]
        
        owner.present(c, animated: true, completion: nil)
        
    }

    func dismiss() {
        owner.navigationController?.popViewController(animated: true)
    }
    
    func showOpenIn(url: URL, sourceRect: CGRect, sourceView: UIView) {
        
        let activityViewController = UIActivityViewController(activityItems: [url],
                                                              applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceView = sourceView
        activityViewController.popoverPresentationController?.sourceRect = sourceRect
        
        owner.present(activityViewController, animated: true, completion: nil)
    }
    
    func showActions(actions: [RRSheet.Action], sourceRect: CGRect, sourceView: UIView) {
        owner.show(viewModels: actions, sourceRect: sourceRect, sourceView: sourceView)       
    }
    
}
