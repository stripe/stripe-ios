//
//  SceneDelegate.swift
//  PaymentModal Example
//
//  Created by Yuki Tokuhiro on 9/14/20.
//  Copyright © 2020 stripe-ios. All rights reserved.
//

import StripePaymentSheet
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        if let urlContext = URLContexts.first {

            let url = urlContext.url
            let stripeHandled = StripeAPI.handleURLCallback(with: url)

            if !stripeHandled {
                // This was not a stripe url, do whatever url handling your app
                // normally does, if any.

                if #available(iOS 15.0, *) {
                    // In this case, we'll pass it to the playground for test configuration.
                    if url.scheme == "stp-paymentsheet-playground" {
                        launchWith(base64String: url.query!)
                    }
                }
            }

        }
    }

    @available(iOS 15.0, *)
    func launchWith(base64String: String) {
        let settings = PaymentSheetTestPlaygroundSettings.fromBase64(base64: base64String, className: PaymentSheetTestPlaygroundSettings.self)!
        let hvc = UIHostingController(rootView: PaymentSheetTestPlayground(settings: settings))
        let navController = UINavigationController(rootViewController: hvc)
        self.window!.rootViewController = navController
    }
    @available(iOS 15.0, *)
    func launchCustomerSheetWith(base64String: String) {
        let settings = PaymentSheetTestPlaygroundSettings.fromBase64(base64: base64String, className: CustomerSheetTestPlaygroundSettings.self)!
        let hvc = UIHostingController(rootView: CustomerSheetTestPlayground(settings: settings))
        let navController = UINavigationController(rootViewController: hvc)
        self.window!.rootViewController = navController
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        #if DEBUG
        if CommandLine.arguments.contains("UITestingDarkModeEnabled") {
            window?.overrideUserInterfaceStyle = .dark
        }
        #endif

        DispatchQueue.main.async {
            // Open URL contexts on app launch if available
            self.scene(scene, openURLContexts: connectionOptions.urlContexts)
        }

        if let playgroundData = ProcessInfo.processInfo.environment["STP_PLAYGROUND_DATA"] {
            if #available(iOS 15.0, *) {
                launchWith(base64String: playgroundData)
            } else {
                assertionFailure("Not supported on < iOS 15")
            }
        } else if let playgroundData = ProcessInfo.processInfo.environment["STP_CUSTOMERSHEET_PLAYGROUND_DATA"] {
            if #available(iOS 15.0, *) {
                launchCustomerSheetWith(base64String: playgroundData)
            } else {
                assertionFailure("Not supported on < iOS 15")
            }
        }

        guard (scene as? UIWindowScene) != nil else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
