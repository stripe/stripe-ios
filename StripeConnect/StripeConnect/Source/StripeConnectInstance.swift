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

    /// Updated when `update(appearance:)` is called
    @Published private(set) var appearance: Appearance

    /// Sends event when `logout()` is called
    let logoutPublisher = ObservableObjectPublisher()

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

    public func createPayments() -> PaymentsViewController {
        .init(connectInstance: self)
    }

    public func update(appearance: Appearance) {
        self.appearance = appearance
    }

    public func logout() async {
        logoutPublisher.send()
    }
}

// MARK: - Internal

extension StripeConnectInstance {

}
