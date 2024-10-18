//
//  SceneDelegate.swift
//  StripeConnectExample
//
//  Created by Chris Mays on 8/21/24.
//

import StripeConnect
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = AppLoadingView().containerViewController
        self.window = window
        window.makeKeyAndVisible()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        let stripeHandled = StripeAPI.handleURLCallback(with: url)
        if !stripeHandled {
            // This was not a Stripe url – handle the URL normally as you would
        }
    }

}
