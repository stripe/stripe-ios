//
//  STPCheckoutSession.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// A CheckoutSession represents a session for a customer to complete a payment.
/// - seealso: https://stripe.com/docs/api/checkout/sessions/object
class STPCheckoutSession: NSObject {

    /// The Stripe ID of the CheckoutSession.
    let stripeId: String

    /// The client secret of the CheckoutSession. Used for embedded or custom UI modes.
    let clientSecret: String?

    /// Monetary totals for this session, or `nil` if not yet available.
    let totals: Checkout.Totals?

    /// Three-letter ISO currency code, in lowercase.
    let currency: String?

    /// The mode of the Checkout Session (payment, setup, or subscription).
    let mode: Checkout.Mode

    /// The status of the Checkout Session (open, complete, or expired). Nullable per API spec.
    let status: Checkout.Status?

    /// The payment status of the Checkout Session (paid, unpaid, or no_payment_required).
    let paymentStatus: Checkout.PaymentStatus

    /// The ID of the PaymentIntent for Checkout Sessions in payment mode.
    let paymentIntentId: String?

    /// The ID of the SetupIntent for Checkout Sessions in setup mode.
    let setupIntentId: String?

    /// The expanded PaymentIntent for this session, if in `payment` or `subscription` mode.
    /// Only populated when the confirm endpoint returns expanded intent objects.
    let paymentIntent: STPPaymentIntent?

    /// The expanded SetupIntent for this session, if in `setup` mode.
    /// Only populated when the confirm endpoint returns expanded intent objects.
    let setupIntent: STPSetupIntent?

    /// The list of payment method types that this CheckoutSession is allowed to use.
    let paymentMethodTypes: [STPPaymentMethodType]

    /// Payment-method-specific configuration for this CheckoutSession.
    let paymentMethodOptions: STPPaymentMethodOptions?

    /// Whether or not this CheckoutSession was created in livemode.
    let livemode: Bool

    /// Customer data including saved payment methods.
    let customer: STPCheckoutSessionCustomer?

    /// The ID of the customer for this Session.
    var customerId: String? {
        return customer?.id
    }

    /// The customer's email address.
    let customerEmail: String?

    /// The URL to the Checkout Session (for hosted UI mode).
    let url: URL?

    /// The URL to redirect the customer back to after authentication or payment completion.
    let returnUrl: String?

    /// The URL the customer will be directed to if they decide to cancel payment.
    let cancelUrl: String?

    /// Applied discounts for this session.
    let discounts: [Checkout.Discount]

    /// The line items associated with this session.
    let lineItems: [Checkout.LineItem]

    /// The available shipping options for this session.
    let shippingOptions: [Checkout.ShippingOption]

    /// The ID of the currently selected shipping option, if any.
    let selectedShippingOptionId: String?

    /// The tax amounts associated with this session.
    let taxAmounts: [STPCheckoutSessionTaxAmount]

    /// The total tax amount for this session, in the smallest currency unit.
    var totalTaxAmount: Int {
        taxAmounts.reduce(0) { $0 + $1.amount }
    }

    /// The currently applied promotion code, if one is present.
    var appliedPromotionCode: String? {
        discounts.first(where: { $0.promotionCode != nil })?.promotionCode
    }

    /// Server-side flag controlling the "Save for future use" checkbox.
    /// Parsed from `customer_managed_saved_payment_methods_offer_save` in the init response.
    let savedPaymentMethodsOfferSave: STPCheckoutSessionSavedPaymentMethodsOfferSave?

    /// Whether billing address collection is required for this session.
    /// Derived from `billing_address_collection == "required"` in the API response.
    let requiresBillingAddress: Bool

    /// The allowed countries for shipping address collection, or `nil` if shipping
    /// address collection is not configured. When non-nil, the merchant should
    /// present a shipping address form restricted to these country codes.
    let allowedShippingCountries: [String]?

    /// Whether the session requires a shipping address.
    /// When `true`, use `allowedShippingCountries` to restrict the address form.
    var requiresShippingAddress: Bool {
        allowedShippingCountries != nil
    }

    /// The localized price options for adaptive pricing.
    let localizedPricesMetas: [STPCheckoutSessionLocalizedPriceMeta]

    /// Exchange rate metadata for adaptive pricing, if available.
    let exchangeRateMeta: STPCheckoutSessionExchangeRateMeta?

    /// Whether adaptive pricing is active for this session.
    let adaptivePricingActive: Bool

    /// Whether automatic tax calculation is enabled for this session.
    let automaticTaxEnabled: Bool

    /// The address source used for automatic tax calculation (e.g. `"billing"` or `"shipping"`).
    /// Only meaningful when ``automaticTaxEnabled`` is `true`.
    let automaticTaxAddressSource: String?

    /// The raw API response used to create this object.
    let allResponseFields: [AnyHashable: Any]

    /// Client-side billing address override, set via Checkout.updateBillingAddress(_:).
    var billingAddressOverride: Checkout.AddressUpdate?

    /// Client-side shipping address override, set via Checkout.updateShippingAddress(_:).
    var shippingAddressOverride: Checkout.AddressUpdate?

    /// Called by confirm handlers with the updated session after a successful confirm.
    /// `Checkout.updateSession(_:)` sets this so the confirm response flows back
    /// to `Checkout` without passing closures through the confirm call chain.
    var onConfirmed: ((STPCheckoutSession) -> Void)?

    /// Returns `true` when the server needs a `tax_region` update for the given address type.
    ///
    /// - Parameter addressType: Either `"billing"` or `"shipping"`.
    func shouldSendTaxRegion(for addressType: String) -> Bool {
        return automaticTaxEnabled && automaticTaxAddressSource == addressType
    }

    /// Returns the expectedAmount if in `payment` mode, `nil` if in `setup` mode, and asserts if in `subscription` or `unknown` mode.
    /// Throws if in `payment` mode but expectedAmount is missing.
    func expectedAmount() throws -> Int? {
        switch mode {
        case .payment:
            guard let total = totals?.total else {
                throw PaymentSheetError.unknown(debugDescription: "Missing expected amount from checkout session")
            }
            return total
        case .setup:
            return nil
        case .unknown, .subscription:
            stpAssertionFailure("Unknown and subscription modes are not currently supported with checkout sessions")
            return nil
        }
    }

    /// Extracts the client secret from the expanded intent based on checkout session mode.
    /// - Parameter mode: The checkout session mode (payment, setup, or subscription)
    /// - Returns: The client secret string from the underlying intent
    /// - Throws: PaymentSheetError if the expected intent is missing
    func clientSecret(for mode: Checkout.Mode) throws -> String {
        switch mode {
        case .setup:
            guard let setupIntent = setupIntent else {
                throw PaymentSheetError.unknown(debugDescription: "Missing setup intent in confirm response")
            }
            return setupIntent.clientSecret
        case .payment:
            guard let paymentIntent = paymentIntent else {
                throw PaymentSheetError.unknown(debugDescription: "Missing payment intent in confirm response")
            }
            return paymentIntent.clientSecret
        case .subscription:
            throw PaymentSheetError.unknown(debugDescription: "Subscriptions are not yet supported with checkout sessions")
        case .unknown:
            throw PaymentSheetError.unknown(debugDescription: "Unknown checkout session mode")
        }
    }

    /// :nodoc:
    override var description: String {
        let props: [String] = [
            String(format: "%@: %p", NSStringFromClass(STPCheckoutSession.self), self),
            "stripeId = \(stripeId)",
            "totals = \(String(describing: totals))",
            "clientSecret = <redacted>",
            "currency = \(String(describing: currency))",
            "mode = \(String(describing: allResponseFields["mode"]))",
            "status = \(String(describing: allResponseFields["status"]))",
            "paymentStatus = \(String(describing: allResponseFields["payment_status"]))",
            "paymentIntentId = \(String(describing: paymentIntentId))",
            "setupIntentId = \(String(describing: setupIntentId))",
            "paymentIntent = \(String(describing: paymentIntent))",
            "setupIntent = \(String(describing: setupIntent))",
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
        totals: Checkout.Totals?,
        currency: String?,
        mode: Checkout.Mode,
        status: Checkout.Status?,
        paymentStatus: Checkout.PaymentStatus,
        paymentIntentId: String?,
        setupIntentId: String?,
        paymentIntent: STPPaymentIntent?,
        setupIntent: STPSetupIntent?,
        paymentMethodTypes: [STPPaymentMethodType],
        paymentMethodOptions: STPPaymentMethodOptions?,
        livemode: Bool,
        customer: STPCheckoutSessionCustomer?,
        customerEmail: String?,
        url: URL?,
        returnUrl: String?,
        cancelUrl: String?,
        discounts: [Checkout.Discount],
        lineItems: [Checkout.LineItem],
        shippingOptions: [Checkout.ShippingOption],
        selectedShippingOptionId: String?,
        taxAmounts: [STPCheckoutSessionTaxAmount],
        savedPaymentMethodsOfferSave: STPCheckoutSessionSavedPaymentMethodsOfferSave?,
        requiresBillingAddress: Bool,
        allowedShippingCountries: [String]?,
        localizedPricesMetas: [STPCheckoutSessionLocalizedPriceMeta],
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta?,
        adaptivePricingActive: Bool,
        automaticTaxEnabled: Bool,
        automaticTaxAddressSource: String?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.stripeId = stripeId
        self.clientSecret = clientSecret
        self.totals = totals
        self.currency = currency
        self.mode = mode
        self.status = status
        self.paymentStatus = paymentStatus
        self.paymentIntentId = paymentIntentId
        self.setupIntentId = setupIntentId
        self.paymentIntent = paymentIntent
        self.setupIntent = setupIntent
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
        self.taxAmounts = taxAmounts
        self.savedPaymentMethodsOfferSave = savedPaymentMethodsOfferSave
        self.requiresBillingAddress = requiresBillingAddress
        self.allowedShippingCountries = allowedShippingCountries
        self.localizedPricesMetas = localizedPricesMetas
        self.exchangeRateMeta = exchangeRateMeta
        self.adaptivePricingActive = adaptivePricingActive
        self.automaticTaxEnabled = automaticTaxEnabled
        self.automaticTaxAddressSource = automaticTaxAddressSource
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPCheckoutSession: STPAPIResponseDecodable {

    @objc
    class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
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
        let currency = dict["currency"] as? String
        let urlString = dict["url"] as? String

        // status is nullable per API spec
        let status: Checkout.Status? = (dict["status"] as? String).map {
            Checkout.Status.status(from: $0)
        }

        // Parse customer object (can be object or string ID for backwards compatibility)
        let customer: STPCheckoutSessionCustomer?
        if let customerDict = dict["customer"] as? [AnyHashable: Any] {
            customer = STPCheckoutSessionCustomer.decodedObject(from: customerDict)
        } else {
            customer = nil
        }

        // Parse collections
        let discounts = Self.parseDiscounts(from: dict)
        let lineItems = Self.parseLineItems(from: dict, defaultCurrency: currency)
        let shippingOptions = Self.parseShippingOptions(from: dict, defaultCurrency: currency)
        let selectedShippingOptionId = Self.parseSelectedShippingOptionId(from: dict)
        let taxAmounts = STPCheckoutSessionTaxAmount.taxAmounts(from: dict)

        // Build totals from total_summary + derived amounts
        let totals: Checkout.Totals? = {
            guard let summary = dict["total_summary"] as? [AnyHashable: Any],
                  let subtotal = summary["subtotal"] as? Int,
                  let total = summary["total"] as? Int,
                  let due = summary["due"] as? Int else {
                return nil
            }
            return Checkout.Totals(
                subtotal: subtotal,
                total: total,
                due: due,
                discount: discounts.reduce(0) { $0 + $1.amount },
                shipping: Self.parseSelectedShippingAmount(from: dict),
                tax: taxAmounts.reduce(0) { $0 + $1.amount }
            )
        }()

        // Parse saved payment methods offer save configuration
        let savedPaymentMethodsOfferSave = STPCheckoutSessionSavedPaymentMethodsOfferSave.decodedObject(
            from: dict["customer_managed_saved_payment_methods_offer_save"] as? [AnyHashable: Any]
        )

        // Parse address collection settings
        let requiresBillingAddress = (dict["billing_address_collection"] as? String) == "required"
        let allowedShippingCountries: [String]? = {
            guard let shippingCollection = dict["shipping_address_collection"] as? [String: Any],
                  let countries = shippingCollection["allowed_countries"] as? [String]
            else { return nil }
            return countries
        }()

        // Parse adaptive pricing data
        let localizedPricesMetas = STPCheckoutSessionLocalizedPriceMeta.localizedPricesMetas(from: dict)
        let exchangeRateMeta = STPCheckoutSessionExchangeRateMeta.decodedObject(from: dict)
        let adaptivePricingActive: Bool = {
            guard let devToolContext = dict["developer_tool_context"] as? [String: Any],
                  let adaptivePricing = devToolContext["adaptive_pricing"] as? [String: Any],
                  let active = adaptivePricing["active"] as? Bool else {
                return false
            }
            return active
        }()

        // Parse tax context for automatic tax settings.
        // The server returns the address source as e.g. "session.billing"; strip
        // the "session." prefix so callers can compare against plain "billing"/"shipping".
        let taxContext = dict["tax_context"] as? [String: Any]
        let automaticTaxEnabled = taxContext?["automatic_tax_enabled"] as? Bool ?? false
        let automaticTaxAddressSource: String? = {
            guard let raw = taxContext?["automatic_tax_address_source"] as? String else { return nil }
            return raw.hasPrefix("session.") ? String(raw.dropFirst("session.".count)) : raw
        }()

        // Parse payment_intent: can be a string ID or an expanded dictionary
        let paymentIntent: STPPaymentIntent?
        let paymentIntentId: String?
        if let piDict = dict["payment_intent"] as? [AnyHashable: Any] {
            paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: piDict)
            paymentIntentId = paymentIntent?.stripeId
        } else {
            paymentIntent = nil
            paymentIntentId = dict["payment_intent"] as? String
        }

        // Parse setup_intent: can be a string ID or an expanded dictionary
        let setupIntent: STPSetupIntent?
        let setupIntentId: String?
        if let siDict = dict["setup_intent"] as? [AnyHashable: Any] {
            setupIntent = STPSetupIntent.decodedObject(fromAPIResponse: siDict)
            setupIntentId = setupIntent?.stripeID
        } else {
            setupIntent = nil
            setupIntentId = dict["setup_intent"] as? String
        }

        return STPCheckoutSession(
            stripeId: stripeId,
            clientSecret: clientSecret,
            totals: totals,
            currency: currency,
            mode: Checkout.Mode.mode(from: rawMode),
            status: status,
            paymentStatus: Checkout.PaymentStatus.paymentStatus(from: rawPaymentStatus),
            paymentIntentId: paymentIntentId,
            setupIntentId: setupIntentId,
            paymentIntent: paymentIntent,
            setupIntent: setupIntent,
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
            taxAmounts: taxAmounts,
            savedPaymentMethodsOfferSave: savedPaymentMethodsOfferSave,
            requiresBillingAddress: requiresBillingAddress,
            allowedShippingCountries: allowedShippingCountries,
            localizedPricesMetas: localizedPricesMetas,
            exchangeRateMeta: exchangeRateMeta,
            adaptivePricingActive: adaptivePricingActive,
            automaticTaxEnabled: automaticTaxEnabled,
            automaticTaxAddressSource: automaticTaxAddressSource,
            allResponseFields: dict
        ) as? Self
    }
}

// MARK: - Parsing Helpers

extension STPCheckoutSession {
    func setupFutureUsage(for paymentMethodType: STPPaymentMethodType) -> String? {
        let perPaymentMethodSetupFutureUsage =
            (allResponseFields["setup_future_usage_for_payment_method_type"] as? [AnyHashable: Any])?[paymentMethodType.identifier] as? String
        if let perPaymentMethodSetupFutureUsage {
            return perPaymentMethodSetupFutureUsage
        }

        if let paymentMethodOptionsSetupFutureUsage = paymentMethodOptions?.setupFutureUsage(for: paymentMethodType) {
            return paymentMethodOptionsSetupFutureUsage
        }

        return allResponseFields["setup_future_usage"] as? String
    }

    func merchantWillSavePaymentMethod(_ paymentMethodType: STPPaymentMethodType) -> Bool {
        guard customerId != nil else {
            return false
        }

        switch mode {
        case .setup, .subscription:
            return true
        case .payment:
            guard let setupFutureUsage = setupFutureUsage(for: paymentMethodType) else {
                return false
            }
            return setupFutureUsage != "none"
        case .unknown:
            return false
        }
    }

    // MARK: Line Items

    static func parseLineItems(from dict: [AnyHashable: Any], defaultCurrency: String?) -> [Checkout.LineItem] {
        guard let lineItemGroup = dict["line_item_group"] as? [AnyHashable: Any],
              let lineItems = lineItemGroup["line_items"] as? [[AnyHashable: Any]] else {
            return []
        }
        return lineItems.compactMap { parseLineItem(from: $0, defaultCurrency: defaultCurrency) }
    }

    private static func parseLineItem(from dict: [AnyHashable: Any], defaultCurrency: String?) -> Checkout.LineItem? {
        guard let id = dict["id"] as? String,
              let quantity = dict["quantity"] as? Int,
              let name = dict["name"] as? String else {
            return nil
        }
        let price = dict["price"] as? [AnyHashable: Any]
        let amount = (price?["unit_amount"] as? Int) ?? 0
        let currency = (price?["currency"] as? String) ?? defaultCurrency ?? "usd"
        return Checkout.LineItem(id: id, name: name, quantity: quantity, unitAmount: amount, currency: currency)
    }

    // MARK: Shipping Options

    static func parseShippingOptions(from dict: [AnyHashable: Any], defaultCurrency: String?) -> [Checkout.ShippingOption] {
        guard let options = dict["shipping_options"] as? [[AnyHashable: Any]] else {
            return []
        }
        return options.compactMap { parseShippingOption(from: $0, defaultCurrency: defaultCurrency) }
    }

    static func parseSelectedShippingOptionId(from dict: [AnyHashable: Any]) -> String? {
        if let lineItemGroup = dict["line_item_group"] as? [AnyHashable: Any],
           let shippingRate = lineItemGroup["shipping_rate"] as? [AnyHashable: Any],
           let id = shippingRate["id"] as? String {
            return id
        }
        return dict["shipping_rate"] as? String
    }

    static func parseSelectedShippingAmount(from dict: [AnyHashable: Any]) -> Int {
        if let lineItemGroup = dict["line_item_group"] as? [AnyHashable: Any],
           let shippingRate = lineItemGroup["shipping_rate"] as? [AnyHashable: Any],
           let amount = shippingRate["amount"] as? Int {
            return amount
        }
        return 0
    }

    private static func parseShippingOption(from dict: [AnyHashable: Any], defaultCurrency: String?) -> Checkout.ShippingOption? {
        if let shippingRate = dict["shipping_rate"] as? [AnyHashable: Any] {
            guard let id = shippingRate["id"] as? String,
                  let displayName = shippingRate["display_name"] as? String,
                  let amount = shippingRate["amount"] as? Int else {
                return nil
            }
            let currency = (shippingRate["currency"] as? String) ?? defaultCurrency ?? "usd"
            return Checkout.ShippingOption(id: id, displayName: displayName, amount: amount, currency: currency)
        }
        if let id = dict["shipping_rate"] as? String {
            return Checkout.ShippingOption(id: id, displayName: "Shipping Option", amount: 0, currency: defaultCurrency ?? "usd")
        }
        return nil
    }

    // MARK: Discounts

    static func parseDiscounts(from dict: [AnyHashable: Any]) -> [Checkout.Discount] {
        let lineItemGroup = dict["line_item_group"] as? [AnyHashable: Any]
        let discountAmounts = lineItemGroup?["discount_amounts"] as? [[AnyHashable: Any]] ?? []
        return discountAmounts.enumerated().compactMap { index, discount in
            parseDiscount(from: discount, fallbackIndex: index)
        }
    }

    private static func parseDiscount(from dict: [AnyHashable: Any], fallbackIndex: Int) -> Checkout.Discount? {
        let couponDict = dict["coupon"] as? [AnyHashable: Any]
        let promotionCodeDict = dict["promotion_code"] as? [AnyHashable: Any]
        let amount = dict["amount"] as? Int ?? 0
        guard amount > 0 else { return nil }
        let couponId = couponDict?["id"] as? String ?? "coupon_\(fallbackIndex)"
        let coupon = Checkout.Coupon(
            id: couponId,
            name: couponDict?["name"] as? String,
            percentOff: couponDict?["percent_off"] as? Double,
            amountOff: couponDict?["amount_off"] as? Int
        )
        return Checkout.Discount(
            coupon: coupon,
            promotionCode: promotionCodeDict?["code"] as? String,
            amount: amount
        )
    }
}
