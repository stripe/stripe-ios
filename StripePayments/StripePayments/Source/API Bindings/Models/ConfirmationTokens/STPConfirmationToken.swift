//
//  STPConfirmationToken.swift
//  StripePayments
//
//  Created by Nick Porter on 9/4/25.
//

import Foundation

/// ConfirmationToken objects represent your customer's payment details. They can be used with PaymentIntents and SetupIntents to collect payments.
/// - seealso: https://stripe.com/docs/api/confirmation_tokens
public class STPConfirmationToken: NSObject, STPAPIResponseDecodable {
    /// You cannot directly instantiate an `STPConfirmationToken`. You should only use one that is returned from the Stripe API.
    required internal init(
        stripeId: String,
        created: Date
    ) {
        self.stripeId = stripeId
        self.created = created
        super.init()
    }

    /// Unique identifier for the object (e.g. `ctoken_...`).
    private(set) public var stripeId: String

    /// Time at which the object was created. Measured in seconds since the Unix epoch.
    private(set) public var created: Date

    /// Time at which this ConfirmationToken expires and can no longer be used to confirm a PaymentIntent or SetupIntent.
    private(set) public var expiresAt: Date?

    /// `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    private(set) public var liveMode = false

    /// ID of the PaymentIntent this token was used to confirm.
    private(set) public var paymentIntentId: String?

    /// ID of the SetupIntent this token was used to confirm.
    private(set) public var setupIntentId: String?

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

    @objc
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }

        // Required fields
        guard let stripeId = response["id"] as? String, !stripeId.isEmpty else {
            return nil
        }

        guard let createdTimestamp = response.stp_date(forKey: "created") else {
            return nil
        }

        let confirmationToken = self.init(
            stripeId: stripeId,
            created: createdTimestamp
        )
        confirmationToken.allResponseFields = response

        // Parse basic fields
        confirmationToken.liveMode = response["livemode"] as? Bool ?? false

        // Parse expires_at timestamp
        confirmationToken.expiresAt = response.stp_date(forKey: "expires_at")

        // Parse payment intent ID
        confirmationToken.paymentIntentId = response["payment_intent"] as? String

        // Parse setup intent ID
        confirmationToken.setupIntentId = response["setup_intent"] as? String

        // Parse payment method preview
        if let paymentMethodPreviewDict = response["payment_method_preview"] as? [AnyHashable: Any] {
            confirmationToken.paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: paymentMethodPreviewDict)
        }

        // Parse return URL
        confirmationToken.returnURL = response["return_url"] as? String

        // Parse setup future usage
        if let setupFutureUsageString = response["setup_future_usage"] as? String {
            confirmationToken.setupFutureUsage = STPPaymentIntentSetupFutureUsage(string: setupFutureUsageString)
        }

        // Parse shipping details
        if let shippingDict = response["shipping"] as? [AnyHashable: Any] {
            confirmationToken.shipping = STPPaymentIntentShippingDetails.decodedObject(fromAPIResponse: shippingDict)
        }

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
            "created = \(created)",
            "expires_at = \(expiresAt?.description ?? "nil")",
            "payment_intent = \(paymentIntentId ?? "nil")",
            "setup_intent = \(setupIntentId ?? "nil")",
            "return_url = \(returnURL ?? "nil")",
            "setup_future_usage = \(setupFutureUsage?.stringValue ?? "nil")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }
}
