//
//  SceneDelegate.swift
//  FinancialConnections Example
//

import StripeCore
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // The `window` is initialized from the storyboard and attached to the scene automatically.

        // Handle any URL or universal link that launched the app.
        if !connectionOptions.urlContexts.isEmpty {
            self.scene(scene, openURLContexts: connectionOptions.urlContexts)
        }
        if let userActivity = connectionOptions.userActivities.first {
            self.scene(scene, continue: userActivity)
        }
    }

    // This method handles opening custom URL schemes (for example, "your-app://stripe-redirect")
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        let stripeHandled = StripeAPI.handleURLCallback(with: url)
        if !stripeHandled {
            // This was not a Stripe url – handle the URL normally as you would
        }
    }

    // This method handles opening universal link URLs (for example, "https://example.com/stripe_ios_callback")
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL
        else {
            return
        }
        let stripeHandled = StripeAPI.handleURLCallback(with: url)
        if !stripeHandled {
            // This was not a Stripe url – handle the URL normally as you would
        }
    }
}
