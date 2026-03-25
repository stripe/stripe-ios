//
//  IntentConfiguration+ClientContext.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/26/25.
//

import Foundation
@_spi(STP) import StripePayments

// MARK: - PaymentSheet IntentConfiguration to Client Context Mapping
extension PaymentSheet.IntentConfiguration {

    /// Creates a client context from this IntentConfiguration for use with confirmation tokens
    /// - Parameter customerId: Optional customer ID
    /// - Returns: A client context with populated fields from the intent configuration
    func createClientContext(customerId: String?) -> STPConfirmationTokenClientContext {
        let clientContext = STPConfirmationTokenClientContext()

        // Map mode and mode-specific properties
        switch mode {
        case let .payment(_, currency, setupFutureUsage, captureMethod, paymentMethodOptions):
            clientContext.mode = "payment"
            clientContext.currency = currency
            clientContext.setupFutureUsage = setupFutureUsage?.rawValue
            clientContext.captureMethod = captureMethod.rawValue
            let pmo = paymentMethodOptions ?? .init()
            clientContext.paymentMethodOptions = pmo.toDictionary(requireCVCRecollection: requireCVCRecollection)

        case .setup(let currency, let setupFutureUsage):
            clientContext.mode = "setup"
            clientContext.currency = currency
            clientContext.setupFutureUsage = setupFutureUsage.rawValue
        }

        // Map common properties
        clientContext.paymentMethodTypes = paymentMethodTypes
        clientContext.onBehalfOf = onBehalfOf
        clientContext.paymentMethodConfiguration = paymentMethodConfigurationId
        clientContext.customer = customerId

        return clientContext
    }
}

// MARK: - PaymentMethodOptions Conversion
private extension PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions {

    /// Converts PaymentSheet PaymentMethodOptions to a dictionary for API encoding
    /// - Parameter requireCVCRecollection: Whether CVC recollection is required for card payments
    /// - Returns: Dictionary representation of payment method options
    func toDictionary(requireCVCRecollection: Bool) -> [String: Any]? {
        var options: [String: Any] = [:]

        // Convert setup future usage values for different payment method types
        if let setupFutureUsageValues = self.setupFutureUsageValues {
            for (paymentMethodType, setupFutureUsage) in setupFutureUsageValues {
                options[paymentMethodType.identifier] = [
                    "setup_future_usage": setupFutureUsage.rawValue
                ]
            }
        }

        // Add CVC recollection for card if enabled
        if requireCVCRecollection {
            var cardOptions = options["card"] as? [String: Any] ?? [:]
            cardOptions["require_cvc_recollection"] = true
            options["card"] = cardOptions
        }

        return options.isEmpty ? nil : options
    }
}
