//
//  StripeConnectInstance.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import JavaScriptCore
import StripeCore
import UIKit

public class StripeConnectInstance {

    let apiClient: STPAPIClient
    let fetchClientSecret: () async -> String?

    private(set) var appearance: Appearance
    private(set) var customFonts: [CustomFontSource]

    /// A collection of weak pointers to all the web views instantiated from this instance
    private let webViews: NSHashTable<ConnectComponentWebView> = .weakObjects()

    /// Keep a reference to one web view that can be used to log out if all other
    /// component web views have been removed from the view hierarchy and deallocated
    private lazy var logoutProxyWebView = ConnectComponentWebView(connectInstance: self, componentType: "")

    /**
     Initializes a StripeConnect instance.

     - Parameters:
       - apiClient: The APIClient instance used to make requests to Stripe.
       - appearance: Describes the appearance of the connect element.
       - customFonts: An array of custom fonts available for use by any embedded components.
       - fetchClientSecret: Closure that fetches client secret.
     */
    public init(apiClient: STPAPIClient = STPAPIClient.shared,
                appearance: Appearance = .default,
                customFonts: [CustomFontSource] = [],
                fetchClientSecret: @escaping () async -> String?) {
        self.apiClient = apiClient
        self.appearance = appearance
        self.customFonts = customFonts
        self.fetchClientSecret = fetchClientSecret

        webViews.add(logoutProxyWebView)
    }

    /**
     Creates an account onboarding view controller.
     - Returns: An AccountOnboardingViewController.
     */
    public func createAccountOnboarding(onExit: @escaping () -> Void) -> AccountOnboardingViewController {
        let vc = AccountOnboardingViewController(connectInstance: self, onExit: onExit)
        webViews.add(vc.webView)
        return vc
    }

    /**
     Creates an account management view controller.
     - Returns: An AccountManagementViewController.
     */
    public func createAccountManagement() -> AccountManagementViewController {
        let vc = AccountManagementViewController(connectInstance: self)
        webViews.add(vc.webView)
        return vc
    }

    /**
     Creates a documents view controller.
     - Returns: A DocumentsViewController
     */
    public func createDocuments() -> DocumentsViewController {
        let vc = DocumentsViewController(connectInstance: self)
        webViews.add(vc.webView)
        return vc
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
     Creates a payment details view controller.
     - Returns: A PaymentDetailsViewController
     */
    public func createPaymentDetails(paymentId: String) -> PaymentDetailsViewController {
        let view = PaymentDetailsViewController(paymentId: paymentId,
                                                connectInstance: self)
        webViews.add(view.webView)
        return view
    }

    /**
     Creates a payouts view controller.
     - Returns: A PayoutsViewController
     */
    public func createPayouts() -> PayoutsViewController {
        let vc = PayoutsViewController(connectInstance: self)
        webViews.add(vc.webView)
        return vc
    }

    /**
     Creates a payouts list view controller.
     - Returns: A PayoutsListViewController
     */
    public func createPayoutsList() -> PayoutsListViewController {
        let vc = PayoutsListViewController(connectInstance: self)
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
        // Log out of each web view
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
