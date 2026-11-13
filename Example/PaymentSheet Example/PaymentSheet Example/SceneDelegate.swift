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
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        if let urlContext = URLContexts.first {

            let url = urlContext.url
            let stripeHandled = StripeAPI.handleURLCallback(with: url)

            if !stripeHandled {
                // This was not a stripe url, do whatever url handling your app
                // normally does, if any.

                // In this case, we'll pass it to the playground for test configuration.
                if CheckoutPlayground.Settings.isExportURL(url) {
                    importCheckoutPlaygroundSettings(from: url, windowScene: windowScene)
                } else if url.scheme == "stp-paymentsheet-playground" {
                    launchWith(base64String: url.query!, windowScene: windowScene)
                }
            }

        }
    }

    func launchWith(base64String: String, windowScene: UIWindowScene) {
        let settings = PaymentSheetTestPlaygroundSettings.fromBase64(base64: base64String, className: PaymentSheetTestPlaygroundSettings.self)!
        launchWith(settings: settings, windowScene: windowScene)
    }

    func launchWith(settingsJSON: String, windowScene: UIWindowScene) {
        let settings: PaymentSheetTestPlaygroundSettings
        do {
            settings = try PaymentSheetTestPlaygroundSettings.fromPartialJSON(settingsJSON)
        } catch {
            fatalError("Invalid STP_PLAYGROUND_SETTINGS_JSON: \(error)")
        }
        launchWith(settings: settings, windowScene: windowScene)
    }

    func launchWith(settings: PaymentSheetTestPlaygroundSettings, windowScene: UIWindowScene) {
        let paymentSheetPlayground = PaymentSheetTestPlayground(settings: settings, appearance: .default)
        let hvc = UIHostingController(rootView: paymentSheetPlayground)
        let navController = UINavigationController(rootViewController: hvc)
        windowScene.windows.first!.rootViewController = navController
    }

    func launchCustomerSheetWith(base64String: String, windowScene: UIWindowScene) {
        let settings = PaymentSheetTestPlaygroundSettings.fromBase64(base64: base64String, className: CustomerSheetTestPlaygroundSettings.self)!
        let customerSheetPlayground = CustomerSheetTestPlayground(settings: settings)
        let hvc = UIHostingController(rootView: customerSheetPlayground)
        let navController = UINavigationController(rootViewController: hvc)
        windowScene.windows.first!.rootViewController = navController
    }

    func launchCheckoutElements(windowScene: UIWindowScene) {
        let settings = ProcessInfo.processInfo.environment["STP_CHECKOUT_PLAYGROUND_SETTINGS"]
            .flatMap { Data(base64Encoded: $0) }
            .flatMap { try? JSONDecoder().decode(CheckoutPlayground.Settings.self, from: $0) }
        launchCheckoutElements(settings: settings, windowScene: windowScene)
    }

    func launchCheckoutElements(settings: CheckoutPlayground.Settings?, errorMessage: String? = nil, windowScene: UIWindowScene) {
        let hostingController = UIHostingController(rootView: CheckoutPlaygroundView(settings: settings, errorMessage: errorMessage))
        let navigationController = UINavigationController(rootViewController: hostingController)
        windowScene.windows.first!.rootViewController = navigationController
    }

    /// Opens the Checkout Playground from a link made by its QR export. Settings the link leaves out, such as
    /// appearance, keep their current values. Saves the settings first so they persist like settings changed
    /// in the playground.
    func importCheckoutPlaygroundSettings(from url: URL, windowScene: UIWindowScene) {
        let currentSettings = UserDefaults.standard.data(forKey: CheckoutPlayground.Settings.nsUserDefaultsKey)
            .flatMap { try? JSONDecoder().decode(CheckoutPlayground.Settings.self, from: $0) }
        guard let settings = CheckoutPlayground.Settings(exportURL: url, base: currentSettings ?? CheckoutPlayground.Settings()),
              let data = try? JSONEncoder().encode(settings) else {
            launchCheckoutElements(
                settings: nil,
                errorMessage: "Couldn't import Checkout Playground settings from the link.",
                windowScene: windowScene
            )
            return
        }
        UserDefaults.standard.set(data, forKey: CheckoutPlayground.Settings.nsUserDefaultsKey)
        launchCheckoutElements(settings: nil, windowScene: windowScene)
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

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
            launchWith(base64String: playgroundData, windowScene: windowScene)
        } else if let settingsJSON = ProcessInfo.processInfo.environment["STP_PLAYGROUND_SETTINGS_JSON"] {
            // Plain JSON with any subset of PaymentSheetTestPlaygroundSettings' keys, e.g. from
            // `SIMCTL_CHILD_STP_PLAYGROUND_SETTINGS_JSON='{"uiStyle":"embedded"}' xcrun simctl launch ...`
            launchWith(settingsJSON: settingsJSON, windowScene: windowScene)
        } else if let playgroundData = ProcessInfo.processInfo.environment["STP_CUSTOMERSHEET_PLAYGROUND_DATA"] {
            launchCustomerSheetWith(base64String: playgroundData, windowScene: windowScene)
        } else if ProcessInfo.processInfo.environment["STP_CHECKOUT_ELEMENTS"] == "true" {
            launchCheckoutElements(windowScene: windowScene)
        }
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
