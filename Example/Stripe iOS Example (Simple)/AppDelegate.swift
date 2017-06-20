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
        let stripePublishableKey = Config.shared.stripePublishableKey
        let backendBaseURL = Config.shared.backendBaseURL

        assert(stripePublishableKey.hasPrefix("pk_"), "You must set your Stripe publishable key in Config.swift to run this app.")
        assert(backendBaseURL != nil, "You must set your backend base url in Config.swift to run this app.")

        MyAPIClient.shared.baseURLString = Config.shared.backendBaseURL

        let rootVC = LoginViewController()
        let navigationController = UINavigationController(rootViewController: rootVC)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navigationController;
        window.makeKeyAndVisible()
        self.window = window
        return true
    }

    // This method is where you handle URL opens if you are using a native scheme URLs (eg "yourexampleapp://")
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let stripeHandled = Stripe.handleURLCallback(with: url)

        if (stripeHandled) {
            return true
        }
        else {
            // This was not a stripe url, do whatever url handling your app
            // normally does, if any.
        }

        return false
    }

    // This method is where you handle URL opens if you are using univeral link URLs (eg "https://example.com/stripe_ios_callback")
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let url = userActivity.webpageURL {
                let stripeHandled = Stripe.handleURLCallback(with: url)

                if (stripeHandled) {
                    return true
                }
                else {
                    // This was not a stripe url, do whatever url handling your app
                    // normally does, if any.
                }
            }
            
        }
        return false
    }
}
