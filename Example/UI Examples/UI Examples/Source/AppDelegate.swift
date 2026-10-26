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

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // STPTestingPublishableKey
        STPAPIClient.shared.publishableKey = "pk_test_ErsyMEOTudSjQR8hh0VrQr5X008sBXGOu6"
        return true
    }

}
