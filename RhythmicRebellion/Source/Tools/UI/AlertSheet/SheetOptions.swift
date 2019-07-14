//
//  AlertViewModel.swift
//  Folia
//
//  Created by Andrew on 7/19/17.
//  Copyright © 2017 Branchfire. All rights reserved.
//

import UIKit
import XLActionController

enum RRSheet {

    enum Option {
        
        case playNow, playNext, playLater, download
        case addToLibrary, addToWishlist, share, delete, forceToPlay, doNotPlay
        case replace, clear
        
        var title: String {
            switch self {
            case .playNow:          return "Play now"
            case .playNext:         return "Play next"
            case .playLater:        return "Play later"
            case .download:         return "Download"
            case .addToLibrary:     return "Add to Library"
            case .addToWishlist:    return "Add to Wishlist"
            case .share:            return "Share"
            case .delete:           return "Delete"
            case .forceToPlay:      return "Force to Play"
            case .doNotPlay:        return "Not to Play"
            case .replace:          return "Replace Playing"
            case .clear:            return "Clear"
            }
        }
        
        var image: UIImage {
            switch self {
            case .playNow:          return R.image.playAction()!
            case .playNext:         return R.image.playNextAction()!
            case .playLater:        return R.image.playLaterAction()!
            case .download:         return R.image.downloadAction()!
            case .addToLibrary:     return R.image.addToLibraryAction()!
            case .addToWishlist:    return R.image.addToWishList()!
            case .share:            return R.image.shareAction()!
            case .delete:           return R.image.deleteAction()!
            case .forceToPlay:      return R.image.forceToPlayAction()!
            case .doNotPlay:        return R.image.doNotPlay()!
            case .replace:          return R.image.replaceAction()!
            case .clear:            return R.image.deleteAction()!
            }
        }
        
    }

    struct Action {
        let option: RRSheet.Option
        let action: () -> Void
    }
    
}





extension RRSheetController {

    class func make(from viewModels: [RRSheet.Action]) -> RRSheetController {
        
        let x = RRSheetController()
        
        viewModels.forEach { i in
            
            x.addAction(XLActionController.Action(RRSheetActionData(title: i.option.title,
                                                                    image: i.option.image),
                                                  style: .default,
                                             executeImmediatelyOnTouch: false,
                                             handler: { _ in
                                                i.action()
                }))
        }
        
        if #available(iOS 11.0, *) {
            if UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0 > 0 {
                x.addAction(XLActionController.Action(RRSheetActionData(title: "",
                                                                        image: UIImage()),
                                                      style: .default,
                                                      executeImmediatelyOnTouch: false,
                                                      handler: { _ in }))
            }
        }
        
        return x
    }
}

extension UIViewController {

    func show(viewModels: [RRSheet.Action],
              sourceRect: CGRect = .zero,
              sourceView: UIView = UIView(),
              completion: (() -> Void)? = nil) {

        let alertActionsController = RRSheetController.make(from: viewModels)

        alertActionsController.popoverPresentationController?.sourceRect = sourceRect
        alertActionsController.popoverPresentationController?.sourceView = sourceView

        self.present(alertActionsController, animated: true, completion: completion)
    }

}
