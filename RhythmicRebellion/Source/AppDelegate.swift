//
//  AppDelegate.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import Firebase
import Fabric
import Crashlytics
import EasyTipView

import AlamofireNetworkActivityLogger

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func setupAppearance() {

        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .top, barMetrics: .default)
        UINavigationBar.appearance().shadowImage = #colorLiteral(red: 0.2509803922, green: 0.2352941176, blue: 0.431372549, alpha: 1).image(CGSize(width: 0.5, height: 0.5))

        UITabBar.appearance(whenContainedInInstancesOf: [PlayerViewController.self]).unselectedItemTintColor = #colorLiteral(red: 0.760392487, green: 0.7985035777, blue: 0.9999999404, alpha: 0.96)
        UITabBar.appearance(whenContainedInInstancesOf: [PlayerViewController.self]).tintColor = #colorLiteral(red: 1, green: 0.3647058824, blue: 0.7137254902, alpha: 0.96)
        UITabBarItem.appearance(whenContainedInInstancesOf: [PlayerViewController.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.760392487, green: 0.7985035777, blue: 0.9999999404, alpha: 0.96),
                                                                                                                 NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14.0)] as [NSAttributedString.Key : Any],
                                                                                                                for: .normal)

        UITabBarItem.appearance(whenContainedInInstancesOf: [PlayerViewController.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor : #colorLiteral(red: 1, green: 0.3639442921, blue: 0.7127844095, alpha: 0.96),
                                                                                                                 NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14.0)] as [NSAttributedString.Key : Any],
                                                                                                                for: .selected)

        UITabBar.appearance(whenContainedInInstancesOf: [TabBarViewController.self]).unselectedItemTintColor = #colorLiteral(red: 0.760392487, green: 0.7985035777, blue: 0.9999999404, alpha: 0.96)
        UITabBar.appearance(whenContainedInInstancesOf: [TabBarViewController.self]).tintColor = #colorLiteral(red: 1, green: 0.3647058824, blue: 0.7137254902, alpha: 0.96)
        UITabBarItem.appearance(whenContainedInInstancesOf: [TabBarViewController.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.760392487, green: 0.7985035777, blue: 0.9999999404, alpha: 0.96),
                                                                                                                 NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14.0)] as [NSAttributedString.Key : Any],
                                                                                                                for: .normal)

        UITabBarItem.appearance(whenContainedInInstancesOf: [TabBarViewController.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor : #colorLiteral(red: 1, green: 0.3639442921, blue: 0.7127844095, alpha: 0.96),
                                                                                                                 NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14.0)] as [NSAttributedString.Key : Any],
                                                                                                                for: .selected)
        UISegmentedControl.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
            .setTitleTextAttributes([NSAttributedString.Key.foregroundColor : #colorLiteral(red: 1, green: 0.3639442921, blue: 0.7127844095, alpha: 1),
                                     NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14.0)] as [NSAttributedString.Key : Any], for: .normal)
        UISegmentedControl.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
            .setTitleTextAttributes([NSAttributedString.Key.foregroundColor : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
                                     NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14.0)] as [NSAttributedString.Key : Any], for: .selected)

        UISegmentedControl.appearance(whenContainedInInstancesOf: [SignUpContentView.self])
            .setTitleTextAttributes([NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1),
                                     NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14.0)] as [NSAttributedString.Key : Any], for: .normal)
        UISegmentedControl.appearance(whenContainedInInstancesOf: [SignUpContentView.self])
            .setTitleTextAttributes([NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.0431372549, green: 0.07450980392, blue: 0.2274509804, alpha: 1),
                                     NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14.0)] as [NSAttributedString.Key : Any], for: .selected)
        
        var tipViewPreferences = EasyTipView.Preferences()
        tipViewPreferences.drawing.font = UIFont.systemFont(ofSize: 12.0)
        tipViewPreferences.drawing.foregroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        tipViewPreferences.drawing.backgroundColor = #colorLiteral(red: 0.2089539468, green: 0.1869146228, blue: 0.349752754, alpha: 1)
        tipViewPreferences.animating.showInitialAlpha = 0
        tipViewPreferences.animating.showDuration = 1.5
        tipViewPreferences.animating.dismissDuration = 1.5
        tipViewPreferences.positioning.textHInset = 5.0
        tipViewPreferences.positioning.textVInset = 5.0
        EasyTipView.globalPreferences = tipViewPreferences
        
    }

    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        ////config services
        FirebaseApp.configure()
        Fabric.with([Crashlytics.self])
        
        NetworkActivityLogger.shared.level = .debug
        NetworkActivityLogger.shared.startLogging()
        
        application.applicationSupportsShakeToEdit = true
        
        ////appearence
        self.setupAppearance()

        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        return Simplicity.application(app, open: url, options: options)
    }
    
    
}

