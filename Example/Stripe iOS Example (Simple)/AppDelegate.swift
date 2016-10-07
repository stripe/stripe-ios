//
//  AppDelegate.swift
//  Stripe iOS Exampe (Simple)
//
//  Created by Jack Flintermann on 1/15/15.
//  Copyright (c) 2015 Stripe. All rights reserved.
//

import UIKit
import Stripe

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let rootVC = BrowseProductsViewController()
        let navigationController = UINavigationController(rootViewController: rootVC)
        let window = UIWindow()
        window.rootViewController = navigationController;
        window.makeKeyAndVisible()
        self.window = window
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return Stripe.handleURLCallback(with: url)
    }
    
}
