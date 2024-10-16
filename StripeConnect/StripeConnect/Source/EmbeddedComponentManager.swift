//
//  EmbeddedComponentManager.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import JavaScriptCore
import StripeCore
import UIKit

/// Manages Connect embedded components
/// - Seealso: https://docs.stripe.com/connect/get-started-connect-embedded-components
/// - Note: Connect embedded components are only available in private beta.
@_spi(PrivateBetaConnect)
@available(iOS 15, *)
public class EmbeddedComponentManager {
    let apiClient: STPAPIClient

    // Weakly held web views who get notified when appearance updates.
    private(set) var childWebViews: NSHashTable<ConnectComponentWebViewController> = .weakObjects()

    let fetchClientSecret: () async -> String?
    let fonts: [EmbeddedComponentManager.CustomFontSource]
    private(set) var appearance: EmbeddedComponentManager.Appearance

    // This should only be used for tests and determines if webview
    // content should load.
    var shouldLoadContent: Bool = true

    /**
     Initializes a StripeConnect instance.

     - Parameters:
       - apiClient: The APIClient instance used to make requests to Stripe.
       - appearance: Customizes the look of Connect embedded components.
       - fonts: An array of custom fonts embedded in your app binary for use by any embedded
       components created from this EmbeddedComponentManager and referenced in `appearance`.
       - fetchClientSecret: ​​The closure that retrieves the [client secret](https://docs.stripe.com/api/account_sessions/object#account_session_object-client_secret)
     returned by `/v1/account_sessions`. This tells the `EmbeddedComponentManager` which account to
     delegate access to. This function is also used to retrieve a client secret function to
     refresh the session when it expires.
     */
    public init(apiClient: STPAPIClient = STPAPIClient.shared,
                appearance: EmbeddedComponentManager.Appearance = .default,
                fonts: [EmbeddedComponentManager.CustomFontSource] = [],
                fetchClientSecret: @escaping () async -> String?) {
        self.apiClient = apiClient
        self.fetchClientSecret = fetchClientSecret
        self.fonts = fonts
        self.appearance = appearance

        assert(Bundle.main.infoDictionary?["NSCameraUsageDescription"] != nil,
               "Embedded components require camera access. Add `NSCameraUsageDescription` to your app's Info.plist file to enable camera access.")
    }

    /// Updates the appearance of components created from this EmbeddedComponentManager
    /// - Seealso: https://docs.stripe.com/connect/get-started-connect-embedded-components#customize-the-look-of-connect-embedded-components
    public func update(appearance: Appearance) {
        self.appearance = appearance
        for item in childWebViews.allObjects {
            item.updateAppearance(appearance: appearance)
        }
    }

    /// Creates a payouts component
    /// - Seealso: https://docs.stripe.com/connect/supported-embedded-components/payouts
    public func createPayoutsViewController() -> PayoutsViewController {
        .init(componentManager: self, loadContent: shouldLoadContent)
    }

    /**
        Creates an account-onboarding component.
        - See also: https://docs.stripe.com/connect/supported-embedded-components/account-onboarding

        - Parameters:
          - fullTermsOfServiceUrl: URL to your [full terms of service agreement](https://docs.stripe.com/connect/service-agreement-types#full).
          - recipientTermsOfServiceUrl: URL to your [recipient terms of service](https://docs.stripe.com/connect/service-agreement-types#recipient) agreement.
          - privacyPolicyUrl: Absolute URL to your privacy policy.
          - skipTermsOfServiceCollection: If true, embedded onboarding skips terms of service collection and you must [collect terms acceptance yourself](https://docs.stripe.com/connect/updating-service-agreements#indicating-acceptance).
          - collectionOptions: Specifies the requirements that Stripe collects from connected accounts
       */
       public func createAccountOnboardingViewController(
           fullTermsOfServiceUrl: URL? = nil,
           recipientTermsOfServiceUrl: URL? = nil,
           privacyPolicyUrl: URL? = nil,
           skipTermsOfServiceCollection: Bool? = nil,
           collectionOptions: AccountCollectionOptions = .init()
       ) -> AccountOnboardingViewController {
           return .init(
            props: .init(
                fullTermsOfServiceUrl: fullTermsOfServiceUrl,
                recipientTermsOfServiceUrl: recipientTermsOfServiceUrl,
                privacyPolicyUrl: privacyPolicyUrl,
                skipTermsOfServiceCollection: skipTermsOfServiceCollection,
                collectionOptions: collectionOptions
            ),
            componentManager: self,
            loadContent: shouldLoadContent)
       }

    @_spi(DashboardOnly)
    public func createPaymentDetailsViewController() -> PaymentDetailsViewController {
        .init(componentManager: self, loadContent: shouldLoadContent)
    }

    @_spi(DashboardOnly)
    public func createAccountManagementViewController(
        collectionOptions: AccountCollectionOptions = .init()
    ) -> AccountManagementViewController {
        .init(componentManager: self,
              collectionOptions: collectionOptions,
              loadContent: shouldLoadContent)
    }

    @_spi(DashboardOnly)
    public func createNotificationBannerViewController(
        collectionOptions: AccountCollectionOptions = .init()
    ) -> NotificationBannerViewController {
        .init(componentManager: self,
              collectionOptions: collectionOptions,
              loadContent: shouldLoadContent)
    }

    /// Used to keep reference of all web views associated with this component manager.
    /// - Parameters:
    ///   - webView: The web view associated with this component manager
    func registerChild(_ webView: ConnectComponentWebViewController) {
        childWebViews.add(webView)
    }
}
