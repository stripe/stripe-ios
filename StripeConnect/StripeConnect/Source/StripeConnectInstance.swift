//
//  StripeConnectInstance.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import Foundation
import StripeCore
import UIKit

public class StripeConnectInstance {

    let apiClient: STPAPIClient
    let fetchClientSecret: () async -> String?

    @Published var appearance: Appearance

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

    public func createPayments() -> PaymentsView {
        .init(connectInstance: self)
    }

    public func createPaymentDetails() -> PaymentDetailsView {
        .init(connectInstance: self)
    }

    public func update(appearance: Appearance) {
        self.appearance = appearance
    }

    public func logout() async {

    }
}

// MARK: - Internal

extension StripeConnectInstance {

}
