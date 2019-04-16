//
//  Simplicity.swift
//  Simplicity
//
//  Created by Edward Jiang on 5/10/16.
//  Copyright © 2016 Stormpath. All rights reserved.
//

import UIKit
import SafariServices

/// Callback handler after an external login completes.
public typealias ExternalLoginCallback = (String?, NSError?) -> Void

/**
 Simplicity is a framework for authenticating with external providers on iOS.
 */
public final class Simplicity {
    private static var currentLoginProvider: LoginProvider?
    private static var callback: ExternalLoginCallback?
    private static var safari: UIViewController?
    
    @available(iOS 9.0, *)
    private static weak var safariDelegate: SFSafariViewControllerDelegate?
    
    /**
     Begin the login flow by redirecting to the LoginProvider's website.
     
     - parameters:
     - loginProvider: The login provider object configured to be used.
     - callback: A callback with the access token, or a SimplicityError.
     */
    public static func login(_ loginProvider: LoginProvider, callback: @escaping ExternalLoginCallback) {
        self.currentLoginProvider = loginProvider
        self.callback = callback
        
        presentSafariView(loginProvider.authorizationURL)
    }
    
    @available(iOS 9.0, *)
    public static func safariLogin(_ loginProvider: LoginProvider,
                                   safariDelegate: SFSafariViewControllerDelegate? = nil,
                                   callback: @escaping ExternalLoginCallback) {
        
        self.safariDelegate = safariDelegate
        self.login(loginProvider, callback: callback)
    }
    
    
    /// Deep link handler (iOS9)
    public static func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        safari?.dismiss(animated: true, completion: nil)
        guard let callback = callback, url.scheme == currentLoginProvider?.urlScheme else {
            return false
        }
        currentLoginProvider?.linkHandler(url, callback: callback)
        currentLoginProvider = nil
        
        return true
    }
    
    /// Deep link handler (<iOS9)
    public static func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return self.application(application, open: url, options: [UIApplication.OpenURLOptionsKey: Any]())
    }
    
    private static func presentSafariView(_ url: URL) {
        if #available(iOS 9, *) {
            let s = SFSafariViewController(url: url)
            s.delegate = safariDelegate
            safari = s
            
            var topController = UIApplication.shared.keyWindow?.rootViewController
            while let vc = topController?.presentedViewController {
                topController = vc
            }
            topController?.present(safari!, animated: true, completion: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
}
