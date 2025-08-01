//
//  STPPaymentIntent.swift
//  StripePayments
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation

/// Capture methods for a STPPaymentIntent
/// - seealso: https://docs.stripe.com/api/payment_intents/object#payment_intent_object-capture_method
@objc public enum STPPaymentIntentCaptureMethod: Int {
    /// Unknown capture method
    case unknown
    /// The PaymentIntent will be automatically captured
    case automatic
    /// The PaymentIntent must be manually captured once it has the status
    /// `STPPaymentIntentStatusRequiresCapture`
    case manual
    /// Asynchronously capture funds when the customer authorizes the payment.
    /// - Note: Recommended over `CaptureMethod.automatic` due to improved latency, but may require additional integration changes.
    /// - Seealso: https://stripe.com/docs/payments/payment-intents/asynchronous-capture-automatic-async
    case automaticAsync

    /// Parse the string and return the correct `STPPaymentIntentCaptureMethod`,
    /// or `STPPaymentIntentCaptureMethodUnknown` if it's unrecognized by this version of the SDK.
    /// - Parameter string: the NSString with the capture method
    internal static func captureMethod(from string: String) -> STPPaymentIntentCaptureMethod {
        let map: [String: STPPaymentIntentCaptureMethod] = [
            "manual": .manual,
            "automatic": .automatic,
            "automatic_async": .automaticAsync,
        ]

        let key = string.lowercased()
        return map[key] ?? .unknown
    }
}

/// Confirmation methods for a STPPaymentIntent
@objc public enum STPPaymentIntentConfirmationMethod: Int {
    /// Unknown confirmation method
    case unknown
    /// Confirmed via publishable key
    case manual
    /// Confirmed via secret key
    case automatic

    /// Parse the string and return the correct `STPPaymentIntentConfirmationMethod`,
    /// or `STPPaymentIntentConfirmationMethodUnknown` if it's unrecognized by this version of the SDK.
    /// - Parameter string: the NSString with the confirmation method
    internal static func confirmationMethod(
        from string: String
    )
        -> STPPaymentIntentConfirmationMethod
    {
        let map: [String: STPPaymentIntentConfirmationMethod] = [
            "automatic": .automatic,
            "manual": .manual,
        ]

        let key = string.lowercased()
        return map[key] ?? .unknown
    }
}

/// A PaymentIntent tracks the process of collecting a payment from your customer.
/// - seealso: https://stripe.com/docs/api#payment_intents
/// - seealso: https://stripe.com/docs/payments/3d-secure
public class STPPaymentIntent: NSObject {

    /// The Stripe ID of the PaymentIntent.
    @objc public let stripeId: String

    /// The client secret used to fetch this PaymentIntent
    @objc public let clientSecret: String

    /// Amount intended to be collected by this PaymentIntent.
    @objc public let amount: Int

    /// If status is `.canceled`, when the PaymentIntent was canceled.
    @objc public let canceledAt: Date?

    /// Capture method of this PaymentIntent
    @objc public let captureMethod: STPPaymentIntentCaptureMethod

    /// Confirmation method of this PaymentIntent
    @objc public let confirmationMethod: STPPaymentIntentConfirmationMethod

    /// When the PaymentIntent was created.
    @objc public let created: Date

    /// The currency associated with the PaymentIntent.
    @objc public let currency: String

    /// The `description` field of the PaymentIntent.
    /// An arbitrary string attached to the object. Often useful for displaying to users.
    @objc public let stripeDescription: String?

    /// Whether or not this PaymentIntent was created in livemode.
    @objc public let livemode: Bool

    /// If `status == .requiresAction`, this
    /// property contains the next action to take for this PaymentIntent.
    @objc public let nextAction: STPIntentAction?

    /// Email address that the receipt for the resulting payment will be sent to.
    @objc public let receiptEmail: String?

    /// The Stripe ID of the Source used in this PaymentIntent.
    @objc public let sourceId: String?

    /// The Stripe ID of the PaymentMethod used in this PaymentIntent.
    @objc public let paymentMethodId: String?

    /// Status of the PaymentIntent
    @objc public let status: STPPaymentIntentStatus

    /// The list of payment method types (e.g. `[NSNumber(value: STPPaymentMethodType.card.rawValue)]`) that this PaymentIntent is allowed to use.
    @objc public let paymentMethodTypes: [NSNumber]

    /// When provided, this property indicates how you intend to use the payment method that your customer provides after the current payment completes. If applicable, additional authentication may be performed to comply with regional legislation or network rules required to enable the usage of the same payment method for additional payments.
    /// Use on_session if you intend to only reuse the payment method when the customer is in your checkout flow. Use off_session if your customer may or may not be in your checkout flow.
    @objc public let setupFutureUsage: STPPaymentIntentSetupFutureUsage

    /// The payment error encountered in the previous PaymentIntent confirmation.
    @objc public let lastPaymentError: STPPaymentIntentLastPaymentError?

    /// Shipping information for this PaymentIntent.
    @objc public let shipping: STPPaymentIntentShippingDetails?

    @objc public let allResponseFields: [AnyHashable: Any]

    /// The optionally expanded PaymentMethod used in this PaymentIntent.
    @objc public let paymentMethod: STPPaymentMethod?

    /// Payment-method-specific configuration for this PaymentIntent.
    @_spi(STP) public let paymentMethodOptions: STPPaymentMethodOptions?

    /// Whether the payment intent has setup for future usage set for a payment method type.
    @_spi(STP) public func isSetupFutureUsageSet(for paymentMethodType: STPPaymentMethodType) -> Bool {
        let setupFutureUsageForPaymentMethodType: String? = setupFutureUsage(for: paymentMethodType)
        return setupFutureUsageForPaymentMethodType != nil && setupFutureUsageForPaymentMethodType != "none"
    }

    @_spi(STP) public func setupFutureUsage(for paymentMethodType: STPPaymentMethodType) -> String? {
        let paymentMethodOptionsSetupFutureUsage = paymentMethodOptions?.setupFutureUsage(for: paymentMethodType)
        // if pmo sfu is non-nil, it overrides the top level sfu
        if let paymentMethodOptionsSetupFutureUsage {
            return paymentMethodOptionsSetupFutureUsage
        }
        return setupFutureUsage.stringValue
    }

    @_spi(STP) public let automaticPaymentMethods: STPIntentAutomaticPaymentMethods?

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentIntent.self), self),
            // Identifier
            "stripeId = \(stripeId)",
            // PaymentIntent details (alphabetical)
            "amount = \(amount)",
            "automaticPaymentMethods = \(String(describing: automaticPaymentMethods))",
            "canceledAt = \(String(describing: canceledAt))",
            "captureMethod = \(String(describing: allResponseFields["capture_method"] as? String))",
            "clientSecret = <redacted>",
            "confirmationMethod = \(String(describing: allResponseFields["confirmation_method"] as? String))",
            "created = \(created)",
            "currency = \(currency)",
            "description = \(String(describing: stripeDescription))",
            "lastPaymentError = \(String(describing: lastPaymentError))",
            "livemode = \(livemode)",
            "nextAction = \(String(describing: nextAction))",
            "paymentMethodId = \(String(describing: paymentMethodId))",
            "paymentMethod = \(String(describing: paymentMethod))",
            "paymentMethodOptions = \(String(describing: paymentMethodOptions))",
            "paymentMethodTypes = \(String(describing: allResponseFields["payment_method_types"] as? [String]))",
            "receiptEmail = \(String(describing: receiptEmail))",
            "setupFutureUsage = \(String(describing: allResponseFields["setup_future_usage"] as? String))",
            "shipping = \(String(describing: shipping))",
            "sourceId = \(String(describing: sourceId))",
            "status = \(String(describing: allResponseFields["status"] as? String))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        allResponseFields: [AnyHashable: Any],
        amount: Int,
        automaticPaymentMethods: STPIntentAutomaticPaymentMethods?,
        canceledAt: Date?,
        captureMethod: STPPaymentIntentCaptureMethod,
        clientSecret: String,
        confirmationMethod: STPPaymentIntentConfirmationMethod,
        created: Date,
        currency: String,
        lastPaymentError: STPPaymentIntentLastPaymentError?,
        livemode: Bool,
        nextAction: STPIntentAction?,
        paymentMethod: STPPaymentMethod?,
        paymentMethodId: String?,
        paymentMethodOptions: STPPaymentMethodOptions?,
        paymentMethodTypes: [NSNumber],
        receiptEmail: String?,
        setupFutureUsage: STPPaymentIntentSetupFutureUsage,
        shipping: STPPaymentIntentShippingDetails?,
        sourceId: String?,
        status: STPPaymentIntentStatus,
        stripeDescription: String?,
        stripeId: String
    ) {
        self.allResponseFields = allResponseFields
        self.amount = amount
        self.automaticPaymentMethods = automaticPaymentMethods
        self.canceledAt = canceledAt
        self.captureMethod = captureMethod
        self.clientSecret = clientSecret
        self.confirmationMethod = confirmationMethod
        self.created = created
        self.currency = currency
        self.lastPaymentError = lastPaymentError
        self.livemode = livemode
        self.nextAction = nextAction
        self.paymentMethod = paymentMethod
        self.paymentMethodId = paymentMethodId
        self.paymentMethodOptions = paymentMethodOptions
        self.paymentMethodTypes = paymentMethodTypes
        self.receiptEmail = receiptEmail
        self.setupFutureUsage = setupFutureUsage
        self.shipping = shipping
        self.sourceId = sourceId
        self.status = status
        self.stripeDescription = stripeDescription
        self.stripeId = stripeId
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPPaymentIntent: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let stripeId = dict["id"] as? String,
            let rawStatus = dict["status"] as? String
        else {
            return nil
        }

        // Check if this is a redacted PaymentIntent by looking for nil required fields
        let isRedacted = dict["amount"] == nil || dict["currency"] == nil || dict["payment_method_types"] == nil || dict["client_secret"] == nil

        // For redacted PaymentIntents, use placeholder values for required fields
        let amount = dict["amount"] as? Int ?? (isRedacted ? -1 : nil)
        let currency = dict["currency"] as? String ?? (isRedacted ? "unknown" : nil)
        let paymentMethodTypeStrings = dict["payment_method_types"] as? [String] ?? (isRedacted ? [] : nil)
        let livemode = dict["livemode"] as? Bool ?? false
        let createdUnixTime = dict["created"] as? TimeInterval ?? Date().timeIntervalSince1970
        let clientSecret = dict["client_secret"] as? String ?? (isRedacted ? Self.RedactedClientSecret : nil)

        // Ensure we have all required values (either real or placeholders)
        guard let finalAmount = amount,
              let finalCurrency = currency,
              let finalPaymentMethodTypes = paymentMethodTypeStrings,
              let finalClientSecret = clientSecret
        else {
            return nil
        }

        let automaticPaymentMethods = STPIntentAutomaticPaymentMethods.decodedObject(
            fromAPIResponse: dict["automatic_payment_methods"] as? [AnyHashable: Any]
        )
        let paymentMethod = STPPaymentMethod.decodedObject(
            fromAPIResponse: dict["payment_method"] as? [AnyHashable: Any]
        )
        let setupFutureUsageString = dict["setup_future_usage"] as? String
        let canceledAtUnixTime = dict["canceled_at"] as? TimeInterval
        return STPPaymentIntent(
            allResponseFields: dict,
            amount: finalAmount,
            automaticPaymentMethods: automaticPaymentMethods,
            canceledAt: canceledAtUnixTime != nil
                ? Date(timeIntervalSince1970: canceledAtUnixTime!) : nil,
            captureMethod: STPPaymentIntentCaptureMethod.captureMethod(
                from: dict["capture_method"] as? String ?? ""
            ),
            clientSecret: finalClientSecret,
            confirmationMethod: STPPaymentIntentConfirmationMethod.confirmationMethod(
                from: dict["confirmation_method"] as? String ?? ""
            ),
            created: Date(timeIntervalSince1970: createdUnixTime),
            currency: finalCurrency,
            lastPaymentError: STPPaymentIntentLastPaymentError.decodedObject(
                fromAPIResponse: dict["last_payment_error"] as? [AnyHashable: Any]
            ),
            livemode: livemode,
            nextAction: STPIntentAction.decodedObject(
                fromAPIResponse: dict["next_action"] as? [AnyHashable: Any]
            ),
            paymentMethod: paymentMethod,
            paymentMethodId: paymentMethod?.stripeId ?? dict["payment_method"] as? String,
            paymentMethodOptions: STPPaymentMethodOptions.decodedObject(
                fromAPIResponse: dict["payment_method_options"] as? [AnyHashable: Any]
            ),
            paymentMethodTypes: STPPaymentMethod.types(from: finalPaymentMethodTypes),
            receiptEmail: dict["receipt_email"] as? String,
            setupFutureUsage: setupFutureUsageString != nil
                ? STPPaymentIntentSetupFutureUsage(string: setupFutureUsageString!) : .none,
            shipping: STPPaymentIntentShippingDetails.decodedObject(
                fromAPIResponse: dict["shipping"] as? [AnyHashable: Any]
            ),
            sourceId: dict["source"] as? String,
            status: STPPaymentIntentStatus.status(from: rawStatus),
            stripeDescription: dict["description"] as? String,
            stripeId: stripeId
        ) as? Self
    }
}

// MARK: - Deprecated
extension STPPaymentIntent {

    /// If `status == STPPaymentIntentStatusRequiresAction`, this
    /// property contains the next source action to take for this PaymentIntent.
    /// @deprecated Use nextAction instead
    @available(*, deprecated, message: "Use nextAction instead", renamed: "nextAction")
    @objc public var nextSourceAction: STPIntentAction? {
        return nextAction
    }
}

// MARK: - Internal
extension STPPaymentIntent {

    /// Helper function for extracting PaymentIntent id from the Client Secret.
    /// This avoids having to pass around both the id and the secret.
    /// - Parameter clientSecret: The `client_secret` from the PaymentIntent
    @_spi(STP) public class func id(fromClientSecret clientSecret: String) -> String? {
        // see parseClientSecret from stripe-js-v3
        // Handle both regular secrets (pi_xxx_secret_yyy) and scoped secrets (pi_xxx_scoped_secret_yyy)
        let secretComponents = clientSecret.components(separatedBy: "_secret_")
        if secretComponents.count >= 2 && secretComponents[0].hasPrefix("pi_") && !secretComponents[1].isEmpty {
            // Check if it's a scoped secret
            if secretComponents[0].hasSuffix("_scoped") {
                // Remove the "_scoped" suffix to get the actual PaymentIntent ID
                let idWithScoped = secretComponents[0]
                let idComponents = idWithScoped.components(separatedBy: "_scoped")
                if idComponents.count >= 1 {
                    return idComponents[0]
                }
            } else {
                // Regular secret format
                return secretComponents[0]
            }
        }
        return nil
    }

    /// Indicates whether this PaymentIntent was created from a redacted API response
    /// when using a scoped client secret.
    /// 
    /// When true, some fields like `amount`, `currency`, and `clientSecret` contain placeholder values
    /// and should not be used for display or business logic.
    @_spi(STP) public var isRedacted: Bool {
        return amount == -1 || currency == "unknown" || clientSecret == Self.RedactedClientSecret || paymentMethodTypes.isEmpty
    }

    private static let RedactedClientSecret = "redacted_client_secret"
}

// MARK: - STPPaymentIntentEnum support

extension STPPaymentIntentStatus {

    /// Parse the string and return the correct `STPPaymentIntentStatus`,
    /// or `STPPaymentIntentStatusUnknown` if it's unrecognized by this version of the SDK.
    /// - Parameter string: the NSString with the status
    internal static func status(from string: String) -> STPPaymentIntentStatus {
        let map: [String: STPPaymentIntentStatus] = [
            "requires_payment_method": .requiresPaymentMethod,
            "requires_confirmation": .requiresConfirmation,
            "requires_action": .requiresAction,
            "processing": .processing,
            "succeeded": .succeeded,
            "requires_capture": .requiresCapture,
            "canceled": .canceled,
        ]

        let key = string.lowercased()
        return map[key] ?? .unknown
    }

    /// Take a `STPPaymentIntentStatus` and return the corresponding string,
    /// or "unknown" if it's not recognized by this function.
    /// - Parameter status: the `STPPaymentIntentStatus` to convert into a string
    internal static func string(from status: STPPaymentIntentStatus) -> String {
        let map: [STPPaymentIntentStatus: String] = [
            .requiresPaymentMethod: "requires_payment_method",
            .requiresConfirmation: "requires_confirmation",
            .requiresAction: "requires_action",
            .processing: "processing",
            .succeeded: "succeeded",
            .requiresCapture: "requires_capture",
            .canceled: "canceled",
            .unknown: "unknown",
        ]

        return map[status] ?? "unknown"
    }
}
