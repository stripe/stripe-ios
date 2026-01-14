//
//  STPCheckoutSession.swift
//  StripePayments
//
//  Created by Nick Porter on 1/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// A CheckoutSession represents a session for a customer to complete a payment.
/// - seealso: https://stripe.com/docs/api/checkout/sessions/object
@_spi(STP) public class STPCheckoutSession: NSObject {

    /// The Stripe ID of the CheckoutSession.
    public let stripeId: String

    /// The client secret of the CheckoutSession. Used for embedded or custom UI modes.
    public let clientSecret: String?

    /// Total of all items after discounts and taxes are applied.
    public let amountTotal: Int?

    /// Three-letter ISO currency code, in lowercase.
    public let currency: String?

    /// The mode of the Checkout Session (payment, setup, or subscription).
    public let mode: STPCheckoutSessionMode

    /// The status of the Checkout Session (open, complete, or expired). Nullable per API spec.
    public let status: STPCheckoutSessionStatus?

    /// The payment status of the Checkout Session (paid, unpaid, or no_payment_required).
    public let paymentStatus: STPCheckoutSessionPaymentStatus

    /// The ID of the PaymentIntent for Checkout Sessions in payment mode.
    public let paymentIntentId: String?

    /// The ID of the SetupIntent for Checkout Sessions in setup mode.
    public let setupIntentId: String?

    /// The list of payment method types that this CheckoutSession is allowed to use.
    public let paymentMethodTypes: [STPPaymentMethodType]

    /// Payment-method-specific configuration for this CheckoutSession.
    public let paymentMethodOptions: STPPaymentMethodOptions?

    /// Whether or not this CheckoutSession was created in livemode.
    public let livemode: Bool

    /// Time at which the CheckoutSession was created.
    public let created: Date

    /// The timestamp at which the Checkout Session will expire.
    public let expiresAt: Date

    /// The ID of the customer for this Session.
    public let customerId: String?

    /// The customer's email address.
    public let customerEmail: String?

    /// The URL to the Checkout Session (for hosted UI mode).
    public let url: URL?

    /// The URL to redirect the customer back to after authentication or payment completion.
    public let returnUrl: String?

    /// The URL the customer will be directed to if they decide to cancel payment.
    public let cancelUrl: String?

    /// The raw API response used to create this object.
    public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    public override var description: String {
        let props: [String] = [
            String(format: "%@: %p", NSStringFromClass(STPCheckoutSession.self), self),
            "stripeId = \(stripeId)",
            "amountTotal = \(String(describing: amountTotal))",
            "clientSecret = <redacted>",
            "currency = \(String(describing: currency))",
            "mode = \(String(describing: allResponseFields["mode"]))",
            "status = \(String(describing: allResponseFields["status"]))",
            "paymentStatus = \(String(describing: allResponseFields["payment_status"]))",
            "paymentIntentId = \(String(describing: paymentIntentId))",
            "setupIntentId = \(String(describing: setupIntentId))",
            "paymentMethodTypes = \(String(describing: allResponseFields["payment_method_types"]))",
            "livemode = \(livemode)",
            "created = \(created)",
            "expiresAt = \(String(describing: expiresAt))",
            "customerId = \(String(describing: customerId))",
            "customerEmail = \(String(describing: customerEmail))",
            "url = \(String(describing: url))",
            "returnUrl = \(String(describing: returnUrl))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        stripeId: String,
        clientSecret: String?,
        amountTotal: Int?,
        currency: String?,
        mode: STPCheckoutSessionMode,
        status: STPCheckoutSessionStatus?,
        paymentStatus: STPCheckoutSessionPaymentStatus,
        paymentIntentId: String?,
        setupIntentId: String?,
        paymentMethodTypes: [STPPaymentMethodType],
        paymentMethodOptions: STPPaymentMethodOptions?,
        livemode: Bool,
        created: Date,
        expiresAt: Date,
        customerId: String?,
        customerEmail: String?,
        url: URL?,
        returnUrl: String?,
        cancelUrl: String?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.stripeId = stripeId
        self.clientSecret = clientSecret
        self.amountTotal = amountTotal
        self.currency = currency
        self.mode = mode
        self.status = status
        self.paymentStatus = paymentStatus
        self.paymentIntentId = paymentIntentId
        self.setupIntentId = setupIntentId
        self.paymentMethodTypes = paymentMethodTypes
        self.paymentMethodOptions = paymentMethodOptions
        self.livemode = livemode
        self.created = created
        self.expiresAt = expiresAt
        self.customerId = customerId
        self.customerEmail = customerEmail
        self.url = url
        self.returnUrl = returnUrl
        self.cancelUrl = cancelUrl
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPCheckoutSession: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        // Required fields per API spec (non-nullable)
        guard let dict = response,
              let stripeId = dict["id"] as? String,
              let livemode = dict["livemode"] as? Bool,
              let created = dict.stp_date(forKey: "created"),
              let expiresAt = dict.stp_date(forKey: "expires_at"),
              let rawMode = dict["mode"] as? String,
              let rawPaymentStatus = dict["payment_status"] as? String,
              let paymentMethodTypeStrings = dict["payment_method_types"] as? [String]
        else {
            return nil
        }

        // Optional fields per API spec (nullable)
        let clientSecret = dict["client_secret"] as? String
        let amountTotal = dict["amount_total"] as? Int
        let currency = dict["currency"] as? String
        let urlString = dict["url"] as? String

        // status is nullable per API spec
        let status: STPCheckoutSessionStatus? = (dict["status"] as? String).map {
            STPCheckoutSessionStatus.status(from: $0)
        }

        return STPCheckoutSession(
            stripeId: stripeId,
            clientSecret: clientSecret,
            amountTotal: amountTotal,
            currency: currency,
            mode: STPCheckoutSessionMode.mode(from: rawMode),
            status: status,
            paymentStatus: STPCheckoutSessionPaymentStatus.paymentStatus(from: rawPaymentStatus),
            paymentIntentId: dict["payment_intent"] as? String,
            setupIntentId: dict["setup_intent"] as? String,
            paymentMethodTypes: STPPaymentMethod.types(from: paymentMethodTypeStrings),
            paymentMethodOptions: STPPaymentMethodOptions.decodedObject(
                fromAPIResponse: dict["payment_method_options"] as? [AnyHashable: Any]
            ),
            livemode: livemode,
            created: created,
            expiresAt: expiresAt,
            customerId: dict["customer"] as? String,
            customerEmail: dict["customer_email"] as? String,
            url: urlString.flatMap { URL(string: $0) },
            returnUrl: dict["return_url"] as? String ?? dict["success_url"] as? String,
            cancelUrl: dict["cancel_url"] as? String,
            allResponseFields: dict
        ) as? Self
    }
}
