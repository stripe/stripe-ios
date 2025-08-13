//
//  AppDelegate.swift
//  UI Examples
//
//  Created by Ben Guo on 7/18/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import Stripe
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // STPTestingPublishableKey
        STPAPIClient.shared.publishableKey = "pk_test_51Rtc1uHi8weFL2MIE8v5WY8TbzfKP7K1dQhQ9HWfixl5A3ZzF8vOjG6x0SjPFGpJ1nYKHXrggWEQ4x2tkHRyFGXW00Q9n3nEPu"

        let rootVC = BrowseViewController()
        let navController = UINavigationController(rootViewController: rootVC)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navController
        window.makeKeyAndVisible()
        self.window = window
        return true
    }

}
