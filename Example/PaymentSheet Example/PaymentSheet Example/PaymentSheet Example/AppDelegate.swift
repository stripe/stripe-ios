//
//  AppDelegate.swift
//  PaymentModal Example
//
//  Created by Yuki Tokuhiro on 9/14/20.
//  Copyright © 2020 stripe-ios. All rights reserved.
//

import Stripe
import UIKit
import Security

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Override point for customization after application launch.
        #if targetEnvironment(simulator)
        if (ProcessInfo.processInfo.environment["UITesting"] != nil) {
            // Disable hardware keyboards in CI:
            let setHardwareLayout = NSSelectorFromString("setHardwareLayout:")
            UITextInputMode.activeInputModes
                .filter({ $0.responds(to: setHardwareLayout) })
                .forEach { $0.perform(setHardwareLayout, with: nil) }

            // Delete cookies before running UI tests
            // TODO(ramont): Use public Link cookie API once it lands.
            for key in ["com.stripe.pay_sid", "com.stripe.link_account"] {
                let query: [String: Any] = [
                    kSecAttrAccount as String: key,
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
                ]

                let status = SecItemDelete(query as CFDictionary)
                assert(
                    status == noErr || status == errSecItemNotFound,
                    "Unexpected status code \(status) when deleting \(key)"
                )
            }
        }
        #endif
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(
            name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(
        _ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}
