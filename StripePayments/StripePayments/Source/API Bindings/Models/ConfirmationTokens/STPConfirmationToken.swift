//
//  STPConfirmationToken.swift
//  StripePayments
//
//  Created by Nick Porter on 9/4/25.
//

import Foundation

/// ConfirmationToken objects represent your customer's payment details. They can be used with PaymentIntents and SetupIntents to collect payments.
/// - seealso: https://stripe.com/docs/api/confirmation_tokens
@_spi(ConfirmationTokensPublicPreview) public class STPConfirmationToken: NSObject, STPAPIResponseDecodable {
    /// You cannot directly instantiate an `STPConfirmationToken`. You should only use one that is returned from the Stripe API.
    required internal override init() {
        super.init()
    }

    /// Unique identifier for the object (e.g. `ctoken_...`).
    private(set) public var stripeId: String = ""

    /// Time at which the object was created. Measured in seconds since the Unix epoch.
    private(set) public var created: Date?

    /// Time at which this ConfirmationToken expires and can no longer be used to confirm a PaymentIntent or SetupIntent.
    private(set) public var expiresAt: Date?

    /// `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    private(set) public var liveMode = false

    /// Data used for generating a Mandate.
    private(set) public var mandateData: STPMandateData?

    /// ID of the PaymentIntent this token was used to confirm.
    private(set) public var paymentIntentId: String?

    /// ID of the SetupIntent this token was used to confirm.
    private(set) public var setupIntentId: String?

    /// Payment-method-specific configuration captured on the token.
    private(set) public var paymentMethodOptions: STPPaymentMethodOptions?

    /// Non-PII preview of payment details captured by the Payment Element.
    private(set) public var paymentMethodPreview: STPPaymentMethodPreview?

    /// Return URL used to confirm the intent for redirect-based methods.
    private(set) public var returnURL: String?

    /// Indicates intent to reuse the payment method.
    private(set) public var setupFutureUsage: STPPaymentIntentSetupFutureUsage?

    /// Shipping information collected on this token.
    private(set) public var shipping: STPPaymentIntentShippingDetails?

    /// :nodoc:
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - STPAPIResponseDecodable

    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()

        // Required fields
        guard let stripeId = dict.stp_string(forKey: "id") else {
            return nil
        }

        let confirmationToken = self.init()
        confirmationToken.allResponseFields = response
        confirmationToken.stripeId = stripeId
        confirmationToken.created = dict.stp_date(forKey: "created")
        confirmationToken.expiresAt = dict.stp_date(forKey: "expires_at")
        confirmationToken.liveMode = dict.stp_bool(forKey: "livemode", or: false)
        confirmationToken.paymentIntentId = dict.stp_string(forKey: "payment_intent")
        confirmationToken.setupIntentId = dict.stp_string(forKey: "setup_intent")
        confirmationToken.returnURL = dict.stp_string(forKey: "return_url")

        // Parse setup_future_usage
        if let setupFutureUsageString = dict.stp_string(forKey: "setup_future_usage") {
            confirmationToken.setupFutureUsage = STPPaymentIntentSetupFutureUsage(string: setupFutureUsageString)
        }

        // Parse nested objects
        confirmationToken.mandateData = STPMandateData.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "mandate_data")
        )
        confirmationToken.paymentMethodOptions = STPPaymentMethodOptions.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "payment_method_options")
        )
        confirmationToken.paymentMethodPreview = STPPaymentMethodPreview.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "payment_method_preview")
        )
        confirmationToken.shipping = STPPaymentIntentShippingDetails.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "shipping")
        )

        return confirmationToken
    }

    // MARK: - NSObject

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPConfirmationToken.self), self),
            // ConfirmationToken details
            "id = \(stripeId)",
            "livemode = \(liveMode ? "YES" : "NO")",
            "created = \(created?.description ?? "nil")",
            "expiresAt = \(expiresAt?.description ?? "nil")",
            "paymentIntentId = \(paymentIntentId ?? "nil")",
            "setupIntentId = \(setupIntentId ?? "nil")",
            "returnURL = \(returnURL ?? "nil")",
            "setupFutureUsage = \(setupFutureUsage?.stringValue ?? "nil")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }
}
