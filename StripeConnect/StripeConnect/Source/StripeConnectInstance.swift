//
//  StripeConnectInstance.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import Foundation
import StripeCore

public class StripeConnectInstance {

    let apiClient: STPAPIClient
    let fetchClientSecret: () async -> String?

    @Published var appearance: Appearance
    @Published var locale: Locale

    /**
     Initializes a StripeConnect instance.

     - Parameters:
       - apiClient: The APIClient instance used to make requests to Stripe.
       - appearance: Describes the appearance of the connect element.
       - locale: The locale to use for the Connect instance.
       - fetchClientSecret: Closure that fetches client secret.
     */
    public init(apiClient: STPAPIClient = STPAPIClient.shared,
                appearance: Appearance = .default,
                locale: Locale = .autoupdatingCurrent,
                fetchClientSecret: @escaping () async -> String?) {
        self.apiClient = apiClient
        self.appearance = appearance
        self.locale = locale
        self.fetchClientSecret = fetchClientSecret
    }

    public func createPayments() -> PaymentsView {
        .init(connectInstance: self)
    }

    public func createPaymentDetails() -> PaymentDetailsView {
        .init(connectInstance: self)
    }

    public func update(appearance: Appearance? = nil,
                       locale: Locale? = nil) {
        if let appearance {
            self.appearance = appearance
        }
        if let locale {
            self.locale = locale
        }
    }

    public func logout() async {

    }
}

// MARK: - Internal

extension StripeConnectInstance {

}
