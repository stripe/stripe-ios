//
//  STPCheckoutSession.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments

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
    public let discounts: [STPCheckoutSessionDiscount]

    /// The line items associated with this session.
    public let lineItems: [STPCheckoutSessionLineItem]

    /// The available shipping options for this session.
    public let shippingOptions: [STPCheckoutSessionShippingOption]

    /// The ID of the currently selected shipping option, if any.
    public let selectedShippingOptionId: String?

    /// The total discount amount applied to this session.
    public let totalDiscountAmount: Int

    /// The total shipping amount applied to this session.
    public let totalShippingAmount: Int

    /// The currently applied promotion code, if one is present.
    public var appliedPromotionCode: String? {
        discounts.first(where: { $0.promotionCode != nil })?.promotionCode?.code
    }

    /// Server-side flag controlling the "Save for future use" checkbox.
    /// Parsed from `customer_managed_saved_payment_methods_offer_save` in the init response.
    public let savedPaymentMethodsOfferSave: STPCheckoutSessionSavedPaymentMethodsOfferSave?

    /// Whether automatic tax calculation is enabled for this session.
    public let automaticTaxEnabled: Bool

    /// The address source used for automatic tax calculation (e.g. `"billing"` or `"shipping"`).
    /// Only meaningful when ``automaticTaxEnabled`` is `true`.
    public let automaticTaxAddressSource: String?

    /// The raw API response used to create this object.
    public let allResponseFields: [AnyHashable: Any]

    /// Client-side billing address override, set via Checkout.updateBillingAddress(_:).
<<<<<<< HEAD
    public internal(set) var billingAddressOverride: Checkout.AddressUpdate?

    /// Client-side shipping address override, set via Checkout.updateShippingAddress(_:).
    public internal(set) var shippingAddressOverride: Checkout.AddressUpdate?

    /// Returns `true` when the server needs a `tax_region` update for the given address type.
    ///
    /// - Parameter addressType: Either `"billing"` or `"shipping"`.
    func shouldSendTaxRegion(for addressType: String) -> Bool {
        return automaticTaxEnabled && automaticTaxAddressSource == addressType
    }
=======
    /// Stored as `Any?` to avoid an upward dependency from the data model to `Checkout.AddressUpdate`.
    public var billingAddressOverride: Any?

    /// Client-side shipping address override, set via Checkout.updateShippingAddress(_:).
    /// Stored as `Any?` to avoid an upward dependency from the data model to `Checkout.AddressUpdate`.
    public var shippingAddressOverride: Any?
>>>>>>> 149a504ca63 (Small bug fixes)

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
            "discounts = \(discounts)",
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
        discounts: [STPCheckoutSessionDiscount],
        lineItems: [STPCheckoutSessionLineItem],
        shippingOptions: [STPCheckoutSessionShippingOption],
        selectedShippingOptionId: String?,
        totalDiscountAmount: Int,
        totalShippingAmount: Int,
        savedPaymentMethodsOfferSave: STPCheckoutSessionSavedPaymentMethodsOfferSave?,
        automaticTaxEnabled: Bool,
        automaticTaxAddressSource: String?,
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
        self.lineItems = lineItems
        self.shippingOptions = shippingOptions
        self.selectedShippingOptionId = selectedShippingOptionId
        self.totalDiscountAmount = totalDiscountAmount
        self.totalShippingAmount = totalShippingAmount
        self.savedPaymentMethodsOfferSave = savedPaymentMethodsOfferSave
        self.automaticTaxEnabled = automaticTaxEnabled
        self.automaticTaxAddressSource = automaticTaxAddressSource
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
        let discounts = STPCheckoutSessionDiscount.discounts(from: dict)
        let lineItems = STPCheckoutSessionLineItem.lineItems(from: dict, defaultCurrency: currency)
        let shippingOptions = STPCheckoutSessionShippingOption.shippingOptions(from: dict, defaultCurrency: currency)
        let selectedShippingOptionId = STPCheckoutSessionShippingOption.selectedShippingOptionId(from: dict)
        let totalDiscountAmount = discounts.reduce(0) { $0 + $1.amount }
        let totalShippingAmount = STPCheckoutSessionShippingOption.selectedShippingAmount(from: dict)

        // Parse saved payment methods offer save configuration
        let savedPaymentMethodsOfferSave = STPCheckoutSessionSavedPaymentMethodsOfferSave.decodedObject(
            from: dict["customer_managed_saved_payment_methods_offer_save"] as? [AnyHashable: Any]
        )

        // Parse tax context for automatic tax settings.
        // The server returns the address source as e.g. "session.billing"; strip
        // the "session." prefix so callers can compare against plain "billing"/"shipping".
        let taxContext = dict["tax_context"] as? [String: Any]
        let automaticTaxEnabled = taxContext?["automatic_tax_enabled"] as? Bool ?? false
        let automaticTaxAddressSource: String? = {
            guard let raw = taxContext?["automatic_tax_address_source"] as? String else { return nil }
            return raw.hasPrefix("session.") ? String(raw.dropFirst("session.".count)) : raw
        }()

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
            paymentMethodTypes: paymentMethodTypeStrings.map { STPPaymentMethod.type(from: $0) },
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
            lineItems: lineItems,
            shippingOptions: shippingOptions,
            selectedShippingOptionId: selectedShippingOptionId,
            totalDiscountAmount: totalDiscountAmount,
            totalShippingAmount: totalShippingAmount,
            savedPaymentMethodsOfferSave: savedPaymentMethodsOfferSave,
            automaticTaxEnabled: automaticTaxEnabled,
            automaticTaxAddressSource: automaticTaxAddressSource,
            allResponseFields: dict
        ) as? Self
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
