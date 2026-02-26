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

    /// Summary of amounts for the CheckoutSession.
    public let totalSummary: STPCheckoutSessionTotalSummary?

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

    /// Customer data including saved payment methods.
    public let customer: STPCheckoutSessionCustomer?

    /// The ID of the customer for this Session.
    public var customerId: String? {
        return customer?.id
    }

    /// The customer's email address.
    public let customerEmail: String?

    /// The URL to the Checkout Session (for hosted UI mode).
    public let url: URL?

    /// The URL to redirect the customer back to after authentication or payment completion.
    public let returnUrl: String?

    /// The URL the customer will be directed to if they decide to cancel payment.
    public let cancelUrl: String?

    /// Applied discounts for this session.
    public let discounts: [CheckoutDiscount]

    /// The currently applied promotion code, if one is present.
    public let appliedPromotionCode: String?

    /// Server-side flag controlling the "Save for future use" checkbox.
    /// Parsed from `customer_managed_saved_payment_methods_offer_save` in the init response.
    public let savedPaymentMethodsOfferSave: STPCheckoutSessionSavedPaymentMethodsOfferSave?

    /// The raw API response used to create this object.
    public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    public override var description: String {
        let props: [String] = [
            String(format: "%@: %p", NSStringFromClass(STPCheckoutSession.self), self),
            "stripeId = \(stripeId)",
            "totalSummary = \(String(describing: totalSummary))",
            "clientSecret = <redacted>",
            "currency = \(String(describing: currency))",
            "mode = \(String(describing: allResponseFields["mode"]))",
            "status = \(String(describing: allResponseFields["status"]))",
            "paymentStatus = \(String(describing: allResponseFields["payment_status"]))",
            "paymentIntentId = \(String(describing: paymentIntentId))",
            "setupIntentId = \(String(describing: setupIntentId))",
            "paymentMethodTypes = \(String(describing: allResponseFields["payment_method_types"]))",
            "livemode = \(livemode)",
            "customerId = \(String(describing: customerId))",
            "customerEmail = \(String(describing: customerEmail))",
            "url = \(String(describing: url))",
            "returnUrl = \(String(describing: returnUrl))",
            "savedPaymentMethodsOfferSave = \(String(describing: savedPaymentMethodsOfferSave))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        stripeId: String,
        clientSecret: String?,
        totalSummary: STPCheckoutSessionTotalSummary?,
        currency: String?,
        mode: STPCheckoutSessionMode,
        status: STPCheckoutSessionStatus?,
        paymentStatus: STPCheckoutSessionPaymentStatus,
        paymentIntentId: String?,
        setupIntentId: String?,
        paymentMethodTypes: [STPPaymentMethodType],
        paymentMethodOptions: STPPaymentMethodOptions?,
        livemode: Bool,
        customer: STPCheckoutSessionCustomer?,
        customerEmail: String?,
        url: URL?,
        returnUrl: String?,
        cancelUrl: String?,
        discounts: [CheckoutDiscount],
        appliedPromotionCode: String?,
        savedPaymentMethodsOfferSave: STPCheckoutSessionSavedPaymentMethodsOfferSave?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.stripeId = stripeId
        self.clientSecret = clientSecret
        self.totalSummary = totalSummary
        self.currency = currency
        self.mode = mode
        self.status = status
        self.paymentStatus = paymentStatus
        self.paymentIntentId = paymentIntentId
        self.setupIntentId = setupIntentId
        self.paymentMethodTypes = paymentMethodTypes
        self.paymentMethodOptions = paymentMethodOptions
        self.livemode = livemode
        self.customer = customer
        self.customerEmail = customerEmail
        self.url = url
        self.returnUrl = returnUrl
        self.cancelUrl = cancelUrl
        self.discounts = discounts
        self.appliedPromotionCode = appliedPromotionCode
        self.savedPaymentMethodsOfferSave = savedPaymentMethodsOfferSave
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPCheckoutSession: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
              let stripeId = dict["session_id"] as? String,
              let livemode = dict["livemode"] as? Bool,
              let rawMode = dict["mode"] as? String,
              let rawPaymentStatus = dict["payment_status"] as? String,
              let paymentMethodTypeStrings = dict["payment_method_types"] as? [String]
        else {
            return nil
        }

        // Optional fields per API spec (nullable)
        let clientSecret = dict["client_secret"] as? String
        let totalSummary = STPCheckoutSessionTotalSummary.decodedObject(
            from: dict["total_summary"] as? [AnyHashable: Any]
        )
        let currency = dict["currency"] as? String
        let urlString = dict["url"] as? String

        // status is nullable per API spec
        let status: STPCheckoutSessionStatus? = (dict["status"] as? String).map {
            STPCheckoutSessionStatus.status(from: $0)
        }

        // Parse customer object (can be object or string ID for backwards compatibility)
        let customer: STPCheckoutSessionCustomer?
        if let customerDict = dict["customer"] as? [AnyHashable: Any] {
            customer = STPCheckoutSessionCustomer.decodedObject(from: customerDict)
        } else {
            customer = nil
        }

        // Parse discounts
        let discounts = mapDiscounts(from: dict)
        let appliedPromotionCode = discounts.first(where: { $0.promotionCode != nil })?.promotionCode

        // Parse saved payment methods offer save configuration
        let savedPaymentMethodsOfferSave = STPCheckoutSessionSavedPaymentMethodsOfferSave.decodedObject(
            from: dict["customer_managed_saved_payment_methods_offer_save"] as? [AnyHashable: Any]
        )

        return STPCheckoutSession(
            stripeId: stripeId,
            clientSecret: clientSecret,
            totalSummary: totalSummary,
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
            customer: customer,
            customerEmail: dict["customer_email"] as? String,
            url: urlString.flatMap { URL(string: $0) },
            returnUrl: dict["return_url"] as? String ?? dict["success_url"] as? String,
            cancelUrl: dict["cancel_url"] as? String,
            discounts: discounts,
            appliedPromotionCode: appliedPromotionCode,
            savedPaymentMethodsOfferSave: savedPaymentMethodsOfferSave,
            allResponseFields: dict
        ) as? Self
    }
}

// MARK: - Discount Parsing

private extension STPCheckoutSession {

    /// Parses discounts from the session response.
    /// Tries top-level `discounts` array first, falls back to `line_item_group.discount_amounts`.
    static func mapDiscounts(from dict: [AnyHashable: Any]) -> [CheckoutDiscount] {
        let discountsFromSession = (dict["discounts"] as? [[AnyHashable: Any]] ?? []).compactMap { mapDiscount(from: $0) }
        if !discountsFromSession.isEmpty {
            return discountsFromSession
        }
        let lineItemGroup = dict["line_item_group"] as? [AnyHashable: Any]
        let discountAmounts = lineItemGroup?["discount_amounts"] as? [[AnyHashable: Any]] ?? []
        return discountAmounts.enumerated().compactMap { index, discount in
            mapDiscountAmount(from: discount, fallbackId: "line_item_group_discount_\(index)")
        }
    }

    /// Parses a single discount from a `discounts` array entry.
    static func mapDiscount(from dict: [AnyHashable: Any]) -> CheckoutDiscount? {
        let discountDict = dict["discount"] as? [AnyHashable: Any] ?? dict
        guard let id = discountDict["id"] as? String else { return nil }
        let couponDict = discountDict["coupon"] as? [AnyHashable: Any]
        let name = couponDict?["name"] as? String
        let percentOff = couponDict?["percent_off"] as? Double
        let amountOff = couponDict?["amount_off"] as? Int
        let amount = dict["amount"] as? Int ?? amountOff ?? 0
        let promotionCode = (discountDict["promotion_code"] as? [AnyHashable: Any])?["code"] as? String
            ?? discountDict["promotion_code"] as? String

        return CheckoutDiscount(
            id: id,
            name: name,
            promotionCode: promotionCode,
            amount: amount,
            percentOff: percentOff,
            amountOff: amountOff
        )
    }

    /// Parses a discount from the `discount_amounts` format in `line_item_group`.
    static func mapDiscountAmount(from dict: [AnyHashable: Any], fallbackId: String) -> CheckoutDiscount? {
        let couponDict = dict["coupon"] as? [AnyHashable: Any]
        let promotionCodeDict = dict["promotion_code"] as? [AnyHashable: Any]
        let amount = dict["amount"] as? Int ?? 0
        guard amount > 0 else { return nil }
        return CheckoutDiscount(
            id: fallbackId,
            name: couponDict?["name"] as? String,
            promotionCode: promotionCodeDict?["code"] as? String,
            amount: amount,
            percentOff: couponDict?["percent_off"] as? Double,
            amountOff: couponDict?["amount_off"] as? Int
        )
    }
}

/// Summary of amounts for a CheckoutSession.
@_spi(STP) public struct STPCheckoutSessionTotalSummary {
    /// The total amount due.
    public let due: Int
    /// The subtotal amount before any adjustments.
    public let subtotal: Int
    /// The total amount after discounts and taxes.
    public let total: Int

    static func decodedObject(from dict: [AnyHashable: Any]?) -> STPCheckoutSessionTotalSummary? {
        guard let dict = dict,
              let due = dict["due"] as? Int,
              let subtotal = dict["subtotal"] as? Int,
              let total = dict["total"] as? Int
        else {
            return nil
        }
        return STPCheckoutSessionTotalSummary(due: due, subtotal: subtotal, total: total)
    }
}
