//
//  CheckoutSheetLoader.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

@MainActor
enum CheckoutSheetLoader {
    static func initSession(configuration: CheckoutController.Configuration) async throws -> CheckoutController.Session {
        // Use a Task instead of async let; see PaymentSheetLoader.load.
        let resources = Task { await PaymentSheetLoader.loadMiscellaneousSingletons() }
        let response = try await configuration.apiClient.initCheckoutSession(
            checkoutSessionId: CheckoutController.extractSessionId(from: configuration.clientSecret),
            adaptivePricingAllowed: configuration.currencySelectorElement != nil
        )
        await resources.value
        return .init(apiResponse: response, localState: .empty, configuration: configuration)
    }
}
