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
    @objc public let stripeId: String

    /// The client secret of the CheckoutSession. Used for embedded or custom UI modes.
    @objc public let clientSecret: String?

    /// Total of all items after discounts and taxes are applied.
    @objc public let amountTotal: Int

    /// Three-letter ISO currency code, in lowercase.
    @objc public let currency: String

    /// The mode of the Checkout Session (payment, setup, or subscription).
    @objc public let mode: STPCheckoutSessionMode

    /// The status of the Checkout Session (open, complete, or expired).
    @objc public let status: STPCheckoutSessionStatus

    /// The payment status of the Checkout Session (paid, unpaid, or no_payment_required).
    @objc public let paymentStatus: STPCheckoutSessionPaymentStatus

    /// The ID of the PaymentIntent for Checkout Sessions in payment mode.
    @objc public let paymentIntentId: String?

    /// The ID of the SetupIntent for Checkout Sessions in setup mode.
    @objc public let setupIntentId: String?

    /// The list of payment method types that this CheckoutSession is allowed to use.
    public let paymentMethodTypes: [STPPaymentMethodType]

    /// Payment-method-specific configuration for this CheckoutSession.
    public let paymentMethodOptions: STPPaymentMethodOptions?

    /// Whether or not this CheckoutSession was created in livemode.
    @objc public let livemode: Bool

    /// Time at which the CheckoutSession was created.
    @objc public let created: Date

    /// The timestamp at which the Checkout Session will expire.
    @objc public let expiresAt: Date?

    /// The ID of the customer for this Session.
    @objc public let customerId: String?

    /// The customer's email address.
    @objc public let customerEmail: String?

    /// The URL to the Checkout Session (for hosted UI mode).
    @objc public let url: URL?

    /// The URL to redirect the customer back to after authentication or payment completion.
    @objc public let returnUrl: String?

    /// The URL the customer will be directed to if they decide to cancel payment.
    @objc public let cancelUrl: String?

    /// The raw API response used to create this object.
    @objc public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            String(format: "%@: %p", NSStringFromClass(STPCheckoutSession.self), self),
            "stripeId = \(stripeId)",
            "amountTotal = \(amountTotal)",
            "clientSecret = <redacted>",
            "currency = \(currency)",
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
        amountTotal: Int,
        currency: String,
        mode: STPCheckoutSessionMode,
        status: STPCheckoutSessionStatus,
        paymentStatus: STPCheckoutSessionPaymentStatus,
        paymentIntentId: String?,
        setupIntentId: String?,
        paymentMethodTypes: [STPPaymentMethodType],
        paymentMethodOptions: STPPaymentMethodOptions?,
        livemode: Bool,
        created: Date,
        expiresAt: Date?,
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
        guard let dict = response,
              let stripeId = dict["id"] as? String,
              let rawStatus = dict["status"] as? String
        else {
            return nil
        }

        let clientSecret = dict["client_secret"] as? String
        let amountTotal = dict["amount_total"] as? Int ?? 0
        let currency = dict["currency"] as? String ?? ""
        let livemode = dict["livemode"] as? Bool ?? false
        let createdUnixTime = dict["created"] as? TimeInterval ?? Date().timeIntervalSince1970

        let paymentMethodTypeStrings = dict["payment_method_types"] as? [String] ?? []

        let expiresAtUnixTime = dict["expires_at"] as? TimeInterval
        let urlString = dict["url"] as? String

        return STPCheckoutSession(
            stripeId: stripeId,
            clientSecret: clientSecret,
            amountTotal: amountTotal,
            currency: currency,
            mode: STPCheckoutSessionMode.mode(from: dict["mode"] as? String ?? ""),
            status: STPCheckoutSessionStatus.status(from: rawStatus),
            paymentStatus: STPCheckoutSessionPaymentStatus.paymentStatus(
                from: dict["payment_status"] as? String ?? ""
            ),
            paymentIntentId: dict["payment_intent"] as? String,
            setupIntentId: dict["setup_intent"] as? String,
            paymentMethodTypes: STPPaymentMethod.types(from: paymentMethodTypeStrings),
            paymentMethodOptions: STPPaymentMethodOptions.decodedObject(
                fromAPIResponse: dict["payment_method_options"] as? [AnyHashable: Any]
            ),
            livemode: livemode,
            created: Date(timeIntervalSince1970: createdUnixTime),
            expiresAt: expiresAtUnixTime.map { Date(timeIntervalSince1970: $0) },
            customerId: dict["customer"] as? String,
            customerEmail: dict["customer_email"] as? String,
            url: urlString.flatMap { URL(string: $0) },
            returnUrl: dict["return_url"] as? String ?? dict["success_url"] as? String,
            cancelUrl: dict["cancel_url"] as? String,
            allResponseFields: dict
        ) as? Self
    }
}
