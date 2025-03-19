//
//  FinancialConnectionsLite.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-19.
//

@_spi(STP) import StripeCore
import UIKit

@_spi(STP) public final class FinancialConnectionsLite {
    /// The client secret of a Stripe `FinancialConnectionsSession` object.
    let clientSecret: String

    /// A URL that that `FinancialConnectionsLite` can use to redirect back to your
    /// app after completing authentication in another app (such as a bank's app or Safari).
    /// If not provided, all bank authentication sessions will happen in a secure browser within this app.
    let returnUrl: URL?

    /// The API Client instance used to make requests to Stripe.
    let apiClient: FCLiteAPIClient = FCLiteAPIClient(backingAPIClient: .shared)

    /// Initializes `FinancialConnectionsLite`.
    /// - Parameters:
    ///   - clientSecret: The client secret of a Stripe `FinancialConnectionsSession` object.
    ///   - returnUrl: A URL that that `FinancialConnectionsLite` can use to redirect back to your app after completing authentication in another app (such as a bank's app or Safari).
    @_spi(STP) public init(
        clientSecret: String,
        returnUrl: URL?
    ) {
        self.clientSecret = clientSecret
        self.returnUrl = returnUrl
    }

    /// Launches the financial connections flow on the provided view controller.
    /// - Parameters:
    ///   - viewController: The view controller from which the pay by bank flow will be presented.
    ///   - completion: A closure that gets called with the result of the financial connections flow.
    @_spi(STP) public func present(
        from viewController: UIViewController,
        completion: @escaping (FinancialConnectionsSDKResult) -> Void
    ) {
        // TODO(mats): Implement.
    }
}
