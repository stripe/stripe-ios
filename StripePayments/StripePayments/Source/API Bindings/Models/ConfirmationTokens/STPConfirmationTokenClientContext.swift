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
@_spi(STP) public class STPConfirmationTokenClientContext: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The mode of this intent, either "payment" or "setup"
    @objc public var mode: String?

    /// Three-letter ISO currency code
    @objc public var currency: String?

    /// Indicates how the payment method is intended to be used in the future
    @objc public var setupFutureUsage: String?

    /// Controls when the funds will be captured (payment mode only)
    @objc public var captureMethod: String?

    /// The payment method types for the intent
    @objc public var paymentMethodTypes: [String]?

    /// The account (if any) for which the funds of the intent are intended
    @objc public var onBehalfOf: String?

    /// Configuration ID for the selected payment method configuration
    @objc public var paymentMethodConfiguration: String?

    /// Customer ID
    @objc public var customer: String?

    /// Payment method specific options as a dictionary
    @objc public var paymentMethodOptions: [String: Any]?

    /// :nodoc:
    @objc public override var description: String {
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

    @objc
    public static func rootObjectName() -> String? {
        return "client_context"
    }

    @objc
    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: mode)): "mode",
            NSStringFromSelector(#selector(getter: currency)): "currency",
            NSStringFromSelector(#selector(getter: setupFutureUsage)): "setup_future_usage",
            NSStringFromSelector(#selector(getter: captureMethod)): "capture_method",
            NSStringFromSelector(#selector(getter: paymentMethodTypes)): "payment_method_types",
            NSStringFromSelector(#selector(getter: onBehalfOf)): "on_behalf_of",
            NSStringFromSelector(#selector(getter: paymentMethodConfiguration)): "payment_method_configuration",
            NSStringFromSelector(#selector(getter: customer)): "customer",
            NSStringFromSelector(#selector(getter: paymentMethodOptions)): "payment_method_options",
        ]
    }

}
