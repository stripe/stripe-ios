//
//  STPPaymentIntent.swift
//  StripePayments
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation

/// Capture methods for a STPPaymentIntent
@objc public enum STPPaymentIntentCaptureMethod: Int {
    /// Unknown capture method
    case unknown
    /// The PaymentIntent will be automatically captured
    case automatic
    /// The PaymentIntent must be manually captured once it has the status
    /// `STPPaymentIntentStatusRequiresCapture`
    case manual

    /// Parse the string and return the correct `STPPaymentIntentCaptureMethod`,
    /// or `STPPaymentIntentCaptureMethodUnknown` if it's unrecognized by this version of the SDK.
    /// - Parameter string: the NSString with the capture method
    internal static func captureMethod(from string: String) -> STPPaymentIntentCaptureMethod {
        let map: [String: STPPaymentIntentCaptureMethod] = [
            "manual": .manual,
            "automatic": .automatic,
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

    /// The ordered payment method preference for this PaymentIntent
    @_spi(STP) public let orderedPaymentMethodTypes: [STPPaymentMethodType]

    /// A list of payment method types that are not activated in live mode, but activated in test mode
    @_spi(STP) public let unactivatedPaymentMethodTypes: [STPPaymentMethodType]

    /// Payment-method-specific configuration for this PaymentIntent.
    @_spi(STP) public let paymentMethodOptions: STPPaymentMethodOptions?

    /// Link-specific settings for this PaymentIntent.
    @_spi(STP) public let linkSettings: LinkSettings?

    /// Country code of the user.
    @_spi(STP) public let countryCode: String?

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentIntent.self), self),
            // Identifier
            "stripeId = \(stripeId)",
            // PaymentIntent details (alphabetical)
            "amount = \(amount)",
            "canceledAt = \(String(describing: canceledAt))",
            "captureMethod = \(String(describing: allResponseFields["capture_method"] as? String))",
            "clientSecret = <redacted>",
            "confirmationMethod = \(String(describing: allResponseFields["confirmation_method"] as? String))",
            "countryCode = \(String(describing: countryCode))",
            "created = \(created)",
            "currency = \(currency)",
            "description = \(String(describing: stripeDescription))",
            "lastPaymentError = \(String(describing: lastPaymentError))",
            "linkSettings = \(String(describing: linkSettings))",
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
            "unactivatedPaymentMethodTypes = \(allResponseFields.stp_array(forKey: "unactivated_payment_method_types") ?? [])",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        allResponseFields: [AnyHashable: Any],
        amount: Int,
        canceledAt: Date?,
        captureMethod: STPPaymentIntentCaptureMethod,
        clientSecret: String,
        confirmationMethod: STPPaymentIntentConfirmationMethod,
        countryCode: String?,
        created: Date,
        currency: String,
        lastPaymentError: STPPaymentIntentLastPaymentError?,
        linkSettings: LinkSettings?,
        livemode: Bool,
        nextAction: STPIntentAction?,
        orderedPaymentMethodTypes: [STPPaymentMethodType],
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
        stripeId: String,
        unactivatedPaymentMethodTypes: [STPPaymentMethodType]
    ) {
        self.allResponseFields = allResponseFields
        self.amount = amount
        self.canceledAt = canceledAt
        self.captureMethod = captureMethod
        self.clientSecret = clientSecret
        self.confirmationMethod = confirmationMethod
        self.countryCode = countryCode
        self.created = created
        self.currency = currency
        self.lastPaymentError = lastPaymentError
        self.linkSettings = linkSettings
        self.livemode = livemode
        self.nextAction = nextAction
        self.orderedPaymentMethodTypes = orderedPaymentMethodTypes
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
        self.unactivatedPaymentMethodTypes = unactivatedPaymentMethodTypes
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPPaymentIntent: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }

        if let paymentMethodPrefDict = response["payment_method_preference"] as? [AnyHashable: Any],
            let paymentIntentDict = paymentMethodPrefDict["payment_intent"] as? [AnyHashable: Any],
            let orderedPaymentMethodTypes = paymentMethodPrefDict["ordered_payment_method_types"]
                as? [String]
        {
            // Consolidates expanded payment_intent and ordered_payment_method_types into singular dict for decoding
            var dict = paymentIntentDict
            dict["country_code"] = paymentMethodPrefDict["country_code"]
            dict["ordered_payment_method_types"] = orderedPaymentMethodTypes
            dict["unactivated_payment_method_types"] = response["unactivated_payment_method_types"]
            dict["link_settings"] = response["link_settings"]
            dict["payment_method_specs"] = response["payment_method_specs"]
            return decodeSTPPaymentIntentObject(fromAPIResponse: dict)
        } else {
            return decodeSTPPaymentIntentObject(fromAPIResponse: response)
        }
    }

    class func decodeSTPPaymentIntentObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self?
    {
        guard let dict = response,
            let stripeId = dict["id"] as? String,
            let clientSecret = dict["client_secret"] as? String,
            let amount = dict["amount"] as? Int,
            let currency = dict["currency"] as? String,
            let rawStatus = dict["status"] as? String,
            let livemode = dict["livemode"] as? Bool,
            let createdUnixTime = dict["created"] as? TimeInterval,
            let paymentMethodTypeStrings = dict["payment_method_types"] as? [String]
        else {
            return nil
        }

        let paymentMethod = STPPaymentMethod.decodedObject(
            fromAPIResponse: dict["payment_method"] as? [AnyHashable: Any]
        )
        let setupFutureUsageString = dict["setup_future_usage"] as? String
        let canceledAtUnixTime = dict["canceled_at"] as? TimeInterval
        let unactivatedPaymentTypes = STPPaymentMethod.paymentMethodTypes(
            from: dict["unactivated_payment_method_types"] as? [String] ?? []
        )
        return STPPaymentIntent(
            allResponseFields: dict,
            amount: amount,
            canceledAt: canceledAtUnixTime != nil
                ? Date(timeIntervalSince1970: canceledAtUnixTime!) : nil,
            captureMethod: STPPaymentIntentCaptureMethod.captureMethod(
                from: dict["capture_method"] as? String ?? ""
            ),
            clientSecret: clientSecret,
            confirmationMethod: STPPaymentIntentConfirmationMethod.confirmationMethod(
                from: dict["confirmation_method"] as? String ?? ""
            ),
            countryCode: dict["country_code"] as? String,
            created: Date(timeIntervalSince1970: createdUnixTime),
            currency: currency,
            lastPaymentError: STPPaymentIntentLastPaymentError.decodedObject(
                fromAPIResponse: dict["last_payment_error"] as? [AnyHashable: Any]
            ),
            linkSettings: LinkSettings.decodedObject(
                fromAPIResponse: dict["link_settings"] as? [AnyHashable: Any]
            ),
            livemode: livemode,
            nextAction: STPIntentAction.decodedObject(
                fromAPIResponse: dict["next_action"] as? [AnyHashable: Any]
            ),
            orderedPaymentMethodTypes: STPPaymentMethod.paymentMethodTypes(
                from: dict["ordered_payment_method_types"] as? [String] ?? paymentMethodTypeStrings
            ),
            paymentMethod: paymentMethod,
            paymentMethodId: paymentMethod?.stripeId ?? dict["payment_method"] as? String,
            paymentMethodOptions: STPPaymentMethodOptions.decodedObject(
                fromAPIResponse: dict["payment_method_options"] as? [AnyHashable: Any]
            ),
            paymentMethodTypes: STPPaymentMethod.types(from: paymentMethodTypeStrings),
            receiptEmail: dict["receipt_email"] as? String,
            setupFutureUsage: setupFutureUsageString != nil
                ? STPPaymentIntentSetupFutureUsage(string: setupFutureUsageString!) : .none,
            shipping: STPPaymentIntentShippingDetails.decodedObject(
                fromAPIResponse: dict["shipping"] as? [AnyHashable: Any]
            ),
            sourceId: dict["source"] as? String,
            status: STPPaymentIntentStatus.status(from: rawStatus),
            stripeDescription: dict["description"] as? String,
            stripeId: stripeId,
            unactivatedPaymentMethodTypes: unactivatedPaymentTypes
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
        let components = clientSecret.components(separatedBy: "_secret_")
        if components.count >= 2 && components[0].hasPrefix("pi_") {
            return components[0]
        } else {
            return nil
        }
    }
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
}
