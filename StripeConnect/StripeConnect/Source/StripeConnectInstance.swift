//
//  StripeConnectInstance.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import Combine
import StripeCore

public class StripeConnectInstance {

    let apiClient: STPAPIClient
    let fetchClientSecret: () async -> String?

    private(set) var appearance: Appearance

    /// A collection of weak pointers to all the web views instantiated from this instance
    private let webViews: NSHashTable<ComponentWebView> = .weakObjects()

    /**
     Initializes a StripeConnect instance.

     - Parameters:
       - apiClient: The APIClient instance used to make requests to Stripe.
       - appearance: Describes the appearance of the connect element.
       - fetchClientSecret: Closure that fetches client secret.
     */
    public init(apiClient: STPAPIClient = STPAPIClient.shared,
                appearance: Appearance = .default,
                fetchClientSecret: @escaping () async -> String?) {
        self.apiClient = apiClient
        self.appearance = appearance
        self.fetchClientSecret = fetchClientSecret
    }

    /**
     Creates a payments view controller.
     - Returns: A PaymentsViewController.
     */
    public func createPayments() -> PaymentsViewController {
        let vc = PaymentsViewController(connectInstance: self)
        webViews.add(vc.webView)
        return vc
    }

    /**
     Creates an account onboarding view controller.
     - Returns: A AccountOnboardingViewController.
     */
    public func createAccountOnboarding(onExit: @escaping () -> Void) -> AccountOnboardingViewController {
        let vc = AccountOnboardingViewController(connectInstance: self, onExit: onExit)
        webViews.add(vc.webView)
        return vc
    }

    /**
     Updates the Connect instance with new parameters.
     - Parameter appearance: Appearance options for the Connect instance.
     */
    public func update(appearance: Appearance) {
        self.appearance = appearance
        webViews.allObjects.forEach { webView in
            webView.updateAppearance(appearance)
        }
    }

    /// Logs the user out of Connect sessions.
    public func logout() async {
        // Log out of each
        let tasks: [Task] = webViews.allObjects.map { webView in
            Task {
                await webView.logout()
            }
        }
        for task in tasks {
            await task.value
        }
    }
}
