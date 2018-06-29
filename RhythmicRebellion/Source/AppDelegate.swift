//
//  AppDelegate.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var appRouter: AppRouter?

    func setupAppearance() {
        UITabBar.appearance(whenContainedInInstancesOf: [PlayerViewController.self]).unselectedItemTintColor = #colorLiteral(red: 0.760392487, green: 0.7985035777, blue: 0.9999999404, alpha: 0.96)
        UITabBar.appearance(whenContainedInInstancesOf: [PlayerViewController.self]).tintColor = #colorLiteral(red: 1, green: 0.3632884026, blue: 0.7128098607, alpha: 0.96)
        UITabBarItem.appearance(whenContainedInInstancesOf: [PlayerViewController.self]).setTitleTextAttributes([NSAttributedStringKey.foregroundColor : #colorLiteral(red: 0.760392487, green: 0.7985035777, blue: 0.9999999404, alpha: 0.96),
                                                                                                                 NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14.0)] as [NSAttributedStringKey : Any],
                                                                                                                for: .normal)

        UITabBarItem.appearance(whenContainedInInstancesOf: [PlayerViewController.self]).setTitleTextAttributes([NSAttributedStringKey.foregroundColor : #colorLiteral(red: 1, green: 0.3639442921, blue: 0.7127844095, alpha: 0.96),
                                                                                                                 NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14.0)] as [NSAttributedStringKey : Any],
                                                                                                                for: .selected)
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        self.setupAppearance()

//        http://player-ngrx2.fan.rebellionretailsite.com/
//        ws://player-ngrx2.rebellionretailsite.com:3000/

//        https://rebels.rhythmic-rebellion.com
//        wss://ws.rebellion-services.com/
        let webSocketService = WebSocketService(with: URL(string: "ws://player-ngrx2.rebellionretailsite.com:3000/")!)
        let appViewController = self.window?.rootViewController as! AppViewController

        let defaultAppRouter = DefaultAppRouter(webSocketService: webSocketService)
        defaultAppRouter.start(controller: appViewController)

        self.appRouter = defaultAppRouter

        return self.appRouter != nil
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

