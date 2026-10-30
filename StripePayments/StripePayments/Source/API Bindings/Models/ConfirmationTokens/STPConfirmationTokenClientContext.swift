//
//  STPConfirmationTokenClientContext.swift
//  StripePayments
//
//  Created by Nick Porter on 9/26/25.
//

import Foundation

/// Client context for a ConfirmationToken, containing information about the payment flow context.
/// Only includes properties that can be populated from PaymentSheet.IntentConfiguration.
/// - seealso: https://stripe.com/docs/api/confirmation_tokens
@_spi(InternalOnlyAPI) public class STPConfirmationTokenClientContext: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The mode of this intent, either "payment" or "setup"
    public var mode: String?

    /// Three-letter ISO currency code
    public var currency: String?

    /// Indicates how the payment method is intended to be used in the future
    public var setupFutureUsage: String?

    /// Controls when the funds will be captured (payment mode only)
    public var captureMethod: String?

    /// The payment method types for the intent
    public var paymentMethodTypes: [String]?

    /// The account (if any) for which the funds of the intent are intended
    public var onBehalfOf: String?

    /// Configuration ID for the selected payment method configuration
    public var paymentMethodConfiguration: String?

    /// Customer ID
    public var customer: String?

    /// Payment method specific options as a dictionary
    public var paymentMethodOptions: [String: Any]?

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPConfirmationTokenClientContext.self), self),
            // Client context details
            "mode = \(mode ?? "")",
            "currency = \(currency ?? "")",
            "setupFutureUsage = \(setupFutureUsage ?? "")",
            "captureMethod = \(captureMethod ?? "")",
            "paymentMethodTypes = \(String(describing: paymentMethodTypes))",
            "onBehalfOf = \(onBehalfOf ?? "")",
            "paymentMethodConfiguration = \(paymentMethodConfiguration ?? "")",
            "customer = \(customer ?? "")",
            "paymentMethodOptions = \(String(describing: paymentMethodOptions))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPFormEncodable

    public static func rootObjectName() -> String? {
        return "client_context"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPConfirmationTokenClientContext.mode: "mode",
            \STPConfirmationTokenClientContext.currency: "currency",
            \STPConfirmationTokenClientContext.setupFutureUsage: "setup_future_usage",
            \STPConfirmationTokenClientContext.captureMethod: "capture_method",
            \STPConfirmationTokenClientContext.paymentMethodTypes: "payment_method_types",
            \STPConfirmationTokenClientContext.onBehalfOf: "on_behalf_of",
            \STPConfirmationTokenClientContext.paymentMethodConfiguration: "payment_method_configuration",
            \STPConfirmationTokenClientContext.customer: "customer",
            \STPConfirmationTokenClientContext.paymentMethodOptions: "payment_method_options",
        ]
    }

}
