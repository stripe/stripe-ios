//
//  PaymentPagesAPIResponse.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Internal response model for the mobile Payment Pages API endpoints.
///
/// These endpoints return Checkout Session state plus mobile-specific fields such as
/// `elements_session`.
class PaymentPagesAPIResponse: NSObject {

    // MARK: - Identifiers

    /// The Stripe ID of the CheckoutSession.
    let id: String

    /// The client secret of the CheckoutSession. Used for embedded or custom UI modes.
    let clientSecret: String?

    /// The business name configured in the Business Public Details settings of your account.
    let businessName: String?

    /// Three-letter ISO currency code, in lowercase.
    let currency: String?

    /// Currency options available when adaptive pricing is active. Empty when not active.
    let currencyOptions: [Checkout.CurrencyOption]

    /// Aggregate discount amounts calculated per discount for all line items.
    let discountAmounts: [Checkout.DiscountAmount]

    /// The customer's email address.
    let email: String?

    /// The line items associated with this session.
    let lineItems: [Checkout.LineItem]

    /// Whether or not this CheckoutSession was created in livemode.
    let livemode: Bool

    /// Payment methods attached to the customer.
    let savedPaymentMethods: [STPPaymentMethod]

    /// The selected shipping option, if any.
    let shipping: Checkout.SelectedShipping?

    /// Available shipping options for this session.
    let shippingOptions: [Checkout.ShippingOption]

    /// Status of the session (status type + payment status).
    let status: Checkout.Status?

    /// Tax computation status and aggregate tax amounts.
    let tax: Checkout.Tax

    /// Tax and discount details for the computed total amount.
    let total: Checkout.Total?

    // MARK: - Internal SDK-only fields

    /// The mode of the Checkout Session (payment, setup, or subscription).
    let mode: Checkout.Mode

    /// The ID of the PaymentIntent for Checkout Sessions in payment mode.
    let paymentIntentId: String?

    /// The ID of the SetupIntent for Checkout Sessions in setup mode.
    let setupIntentId: String?

    /// The expanded PaymentIntent for this session, if in `payment` or `subscription` mode.
    let paymentIntent: STPPaymentIntent?

    /// The expanded SetupIntent for this session, if in `setup` mode.
    let setupIntent: STPSetupIntent?

    /// The list of payment method types that this CheckoutSession is allowed to use.
    let paymentMethodTypes: [STPPaymentMethodType]

    /// Payment-method-specific configuration for this CheckoutSession.
    let paymentMethodOptions: STPPaymentMethodOptions?

    /// Customer data including saved payment methods.
    let customer: STPCheckoutSessionCustomer?

    /// The URL to the Checkout Session (for hosted UI mode).
    let url: URL?

    /// The URL to redirect to after authentication or payment completion.
    let returnUrl: String?

    /// The URL the customer will be directed to if they decide to cancel payment.
    let cancelUrl: String?

    /// Server-side flag controlling the "Save for future use" checkbox.
    let savedPaymentMethodsOfferSave: STPCheckoutSessionSavedPaymentMethodsOfferSave?

    /// Top-level setup_future_usage for payment-mode checkout sessions.
    let setupFutureUsage: String?

    /// Per-payment-method setup_future_usage overrides for payment-mode checkout sessions.
    let setupFutureUsageForPaymentMethodType: [String: String]

    /// Whether billing address collection is required for this session.
    let requiresBillingAddress: Bool

    /// The allowed countries for shipping address collection, or `nil` if shipping
    /// address collection is not configured.
    let allowedShippingCountries: [String]?

    /// The localized price options for adaptive pricing (internal decoder used by the
    /// adaptive-pricing UI; the public surface is ``currencyOptions``).
    let localizedPricesMetas: [STPCheckoutSessionLocalizedPriceMeta]

    /// Exchange rate metadata for adaptive pricing, if available.
    let exchangeRateMeta: STPCheckoutSessionExchangeRateMeta?

    /// Whether adaptive pricing is active for this session.
    let adaptivePricingActive: Bool

    /// Whether automatic tax calculation is enabled for this session.
    let automaticTaxEnabled: Bool

    /// The address source used for automatic tax calculation (e.g. `"billing"` or `"shipping"`).
    let automaticTaxAddressSource: String?

    /// The elements session embedded in this checkout session.
    let elementsSession: STPElementsSession

    /// The raw API response used to create this object.
    let allResponseFields: [AnyHashable: Any]

    /// Extracts the client secret from the expanded PaymentIntent or SetupIntent based on mode.
    func intentClientSecret() throws -> String {
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
            String(format: "%@: %p", NSStringFromClass(PaymentPagesAPIResponse.self), self),
            "id = \(id)",
            "total = \(String(describing: total))",
            "clientSecret = <redacted>",
            "currency = \(String(describing: currency))",
            "mode = \(String(describing: allResponseFields["mode"]))",
            "status = \(String(describing: status))",
            "paymentIntentId = \(String(describing: paymentIntentId))",
            "setupIntentId = \(String(describing: setupIntentId))",
            "paymentIntent = \(String(describing: paymentIntent))",
            "setupIntent = \(String(describing: setupIntent))",
            "paymentMethodTypes = \(String(describing: allResponseFields["payment_method_types"]))",
            "livemode = \(livemode)",
            "customerId = \(String(describing: customer?.id))",
            "email = \(String(describing: email))",
            "url = \(String(describing: url))",
            "returnUrl = \(String(describing: returnUrl))",
            "discountAmounts = \(discountAmounts)",
            "savedPaymentMethodsOfferSave = \(String(describing: savedPaymentMethodsOfferSave))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        id: String,
        clientSecret: String?,
        businessName: String?,
        currency: String?,
        currencyOptions: [Checkout.CurrencyOption],
        discountAmounts: [Checkout.DiscountAmount],
        email: String?,
        lineItems: [Checkout.LineItem],
        livemode: Bool,
        savedPaymentMethods: [STPPaymentMethod],
        shipping: Checkout.SelectedShipping?,
        shippingOptions: [Checkout.ShippingOption],
        status: Checkout.Status?,
        tax: Checkout.Tax,
        total: Checkout.Total?,
        mode: Checkout.Mode,
        paymentIntentId: String?,
        setupIntentId: String?,
        paymentIntent: STPPaymentIntent?,
        setupIntent: STPSetupIntent?,
        paymentMethodTypes: [STPPaymentMethodType],
        paymentMethodOptions: STPPaymentMethodOptions?,
        customer: STPCheckoutSessionCustomer?,
        url: URL?,
        returnUrl: String?,
        cancelUrl: String?,
        savedPaymentMethodsOfferSave: STPCheckoutSessionSavedPaymentMethodsOfferSave?,
        setupFutureUsage: String?,
        setupFutureUsageForPaymentMethodType: [String: String],
        requiresBillingAddress: Bool,
        allowedShippingCountries: [String]?,
        localizedPricesMetas: [STPCheckoutSessionLocalizedPriceMeta],
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta?,
        adaptivePricingActive: Bool,
        automaticTaxEnabled: Bool,
        automaticTaxAddressSource: String?,
        elementsSession: STPElementsSession,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.id = id
        self.clientSecret = clientSecret
        self.businessName = businessName
        self.currency = currency
        self.currencyOptions = currencyOptions
        self.discountAmounts = discountAmounts
        self.email = email
        self.lineItems = lineItems
        self.livemode = livemode
        self.savedPaymentMethods = savedPaymentMethods
        self.shipping = shipping
        self.shippingOptions = shippingOptions
        self.status = status
        self.tax = tax
        self.total = total
        self.mode = mode
        self.paymentIntentId = paymentIntentId
        self.setupIntentId = setupIntentId
        self.paymentIntent = paymentIntent
        self.setupIntent = setupIntent
        self.paymentMethodTypes = paymentMethodTypes
        self.paymentMethodOptions = paymentMethodOptions
        self.customer = customer
        self.url = url
        self.returnUrl = returnUrl
        self.cancelUrl = cancelUrl
        self.savedPaymentMethodsOfferSave = savedPaymentMethodsOfferSave
        self.setupFutureUsage = setupFutureUsage
        self.setupFutureUsageForPaymentMethodType = setupFutureUsageForPaymentMethodType
        self.requiresBillingAddress = requiresBillingAddress
        self.allowedShippingCountries = allowedShippingCountries
        self.localizedPricesMetas = localizedPricesMetas
        self.exchangeRateMeta = exchangeRateMeta
        self.adaptivePricingActive = adaptivePricingActive
        self.automaticTaxEnabled = automaticTaxEnabled
        self.automaticTaxAddressSource = automaticTaxAddressSource
        self.elementsSession = elementsSession
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable

extension PaymentPagesAPIResponse: STPAPIResponseDecodable {

    @objc
    class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
              let id = dict["session_id"] as? String,
              let livemode = dict["livemode"] as? Bool,
              let rawMode = dict["mode"] as? String,
              let rawPaymentStatus = dict["payment_status"] as? String,
              let paymentMethodTypeStrings = dict["payment_method_types"] as? [String]
        else {
            return nil
        }

        // Optional / nullable fields
        let clientSecret = dict["client_secret"] as? String
        let currency = dict["currency"] as? String
        let urlString = dict["url"] as? String

        // Customer (object or string ID for backwards compatibility)
        let customer: STPCheckoutSessionCustomer?
        if let customerDict = dict["customer"] as? [AnyHashable: Any] {
            customer = STPCheckoutSessionCustomer.decodedObject(from: customerDict)
        } else {
            customer = nil
        }

        // Status (type + payment status)
        let paymentStatus = Checkout.PaymentStatus.paymentStatus(from: rawPaymentStatus)
        let status: Checkout.Status? = {
            guard let rawStatus = dict["status"] as? String else { return nil }
            return Checkout.Status(
                type: Checkout.StatusType.statusType(from: rawStatus),
                paymentStatus: paymentStatus
            )
        }()

        // Collections
        let publicTaxAmounts = Self.parseSessionTaxAmounts(from: dict, currency: currency)

        let discountAmounts = Self.parseDiscountAmounts(from: dict, currency: currency)
        let lineItems = Self.parseLineItems(from: dict, defaultCurrency: currency)
        let shippingOptions = Self.parseShippingOptions(from: dict, defaultCurrency: currency)

        // Total
        let total: Checkout.Total? = {
            guard let summary = dict["total_summary"] as? [AnyHashable: Any],
                  let subtotal = summary["subtotal"] as? Int,
                  let totalValue = summary["total"] as? Int else {
                return nil
            }
            let taxInclusiveValue = publicTaxAmounts.filter { $0.inclusive }.reduce(0) { $0 + $1.amount.minorUnitsAmount }
            let taxExclusiveValue = publicTaxAmounts.filter { !$0.inclusive }.reduce(0) { $0 + $1.amount.minorUnitsAmount }
            let shippingValue = Self.parseSelectedShippingAmount(from: dict)
            let discountValue = discountAmounts.reduce(0) { $0 + $1.amount.minorUnitsAmount }
            let appliedBalanceValue = (summary["applied_balance"] as? Int) ?? 0
            let balanceAppliedToNextInvoice = (summary["balance_applied_to_next_invoice"] as? Bool) ?? false

            return Checkout.Total(
                subtotal: makeAmount(subtotal, currency: currency),
                taxExclusive: makeAmount(taxExclusiveValue, currency: currency),
                taxInclusive: makeAmount(taxInclusiveValue, currency: currency),
                shippingRate: makeAmount(shippingValue, currency: currency),
                discount: makeAmount(discountValue, currency: currency),
                total: makeAmount(totalValue, currency: currency),
                appliedBalance: makeAmount(appliedBalanceValue, currency: currency),
                balanceAppliedToNextInvoice: balanceAppliedToNextInvoice
            )
        }()

        // Tax
        let taxStatus: Checkout.TaxStatus = {
            let taxMeta = dict["tax_meta"] as? [String: Any]
            let computationType = taxMeta?["computation_type"] as? String
            guard computationType == "automatic" else {
                return .ready
            }

            let status = taxMeta?["status"] as? String
            switch status {
            case "complete":
                return .ready
            case "requires_location_inputs":
                let taxContext = dict["tax_context"] as? [String: Any]
                let addressSource = taxContext?["automatic_tax_address_source"] as? String
                return addressSource == "session.shipping" ? .requiresShippingAddress : .requiresBillingAddress
            case "failed":
                return .unknown
            default:
                return .ready
            }
        }()
        let tax = Checkout.Tax(
            status: taxStatus,
            taxAmounts: publicTaxAmounts.isEmpty ? nil : publicTaxAmounts
        )

        // Saved payment methods offer save / setup_future_usage
        let savedPaymentMethodsOfferSave = STPCheckoutSessionSavedPaymentMethodsOfferSave.decodedObject(
            from: dict["customer_managed_saved_payment_methods_offer_save"] as? [AnyHashable: Any]
        )
        let setupFutureUsage = dict["setup_future_usage"] as? String
        let setupFutureUsageForPaymentMethodType = dict["setup_future_usage_for_payment_method_type"] as? [String: String] ?? [:]

        // Address collection settings
        let requiresBillingAddress = (dict["billing_address_collection"] as? String) == "required"
        let allowedShippingCountries: [String]? = {
            guard let shippingCollection = dict["shipping_address_collection"] as? [String: Any],
                  let countries = shippingCollection["allowed_countries"] as? [String]
            else { return nil }
            return countries
        }()

        // Adaptive pricing data (internal decoders + public CurrencyOption mapping)
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
        let currencyOptions = Self.makeCurrencyOptions(
            from: localizedPricesMetas,
            exchangeRateMeta: exchangeRateMeta
        )

        // Tax context for automatic-tax address source.
        let taxContext = dict["tax_context"] as? [String: Any]
        let automaticTaxEnabled = taxContext?["automatic_tax_enabled"] as? Bool ?? false
        let automaticTaxAddressSource: String? = {
            guard let raw = taxContext?["automatic_tax_address_source"] as? String else { return nil }
            return raw.hasPrefix("session.") ? String(raw.dropFirst("session.".count)) : raw
        }()

        // payment_intent / setup_intent (string ID or expanded dictionary)
        let paymentIntent: STPPaymentIntent?
        let paymentIntentId: String?
        if let piDict = dict["payment_intent"] as? [AnyHashable: Any] {
            paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: piDict)
            paymentIntentId = paymentIntent?.stripeId
        } else {
            paymentIntent = nil
            paymentIntentId = dict["payment_intent"] as? String
        }
        let setupIntent: STPSetupIntent?
        let setupIntentId: String?
        if let siDict = dict["setup_intent"] as? [AnyHashable: Any] {
            setupIntent = STPSetupIntent.decodedObject(fromAPIResponse: siDict)
            setupIntentId = setupIntent?.stripeID
        } else {
            setupIntent = nil
            setupIntentId = dict["setup_intent"] as? String
        }

        // Selected shipping
        let shipping = Self.parseSelectedShipping(
            from: dict,
            shippingOptions: shippingOptions,
            currency: currency
        )

        let savedPaymentMethods: [STPPaymentMethod] = customer?.paymentMethods ?? []

        let businessName = (dict["elements_session"] as? [String: Any])?["business_name"] as? String

        guard let elementsSessionDict = dict["elements_session"] as? [AnyHashable: Any],
              let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionDict)
        else { return nil }
        if automaticTaxEnabled && automaticTaxAddressSource == "billing" {
            elementsSession.disableLinkForAutomaticTaxBilling = true
        }

        let email = (dict["customer_email"] as? String) ?? customer?.email

        return PaymentPagesAPIResponse(
            id: id,
            clientSecret: clientSecret,
            businessName: businessName,
            currency: currency,
            currencyOptions: currencyOptions,
            discountAmounts: discountAmounts,
            email: email,
            lineItems: lineItems,
            livemode: livemode,
            savedPaymentMethods: savedPaymentMethods,
            shipping: shipping,
            shippingOptions: shippingOptions,
            status: status,
            tax: tax,
            total: total,
            mode: Checkout.Mode.mode(from: rawMode),
            paymentIntentId: paymentIntentId,
            setupIntentId: setupIntentId,
            paymentIntent: paymentIntent,
            setupIntent: setupIntent,
            paymentMethodTypes: paymentMethodTypeStrings.map { STPPaymentMethod.type(from: $0) },
            paymentMethodOptions: STPPaymentMethodOptions.decodedObject(
                fromAPIResponse: dict["payment_method_options"] as? [AnyHashable: Any]
            ),
            customer: customer,
            url: urlString.flatMap { URL(string: $0) },
            returnUrl: dict["return_url"] as? String ?? dict["success_url"] as? String,
            cancelUrl: dict["cancel_url"] as? String,
            savedPaymentMethodsOfferSave: savedPaymentMethodsOfferSave,
            setupFutureUsage: setupFutureUsage,
            setupFutureUsageForPaymentMethodType: setupFutureUsageForPaymentMethodType,
            requiresBillingAddress: requiresBillingAddress,
            allowedShippingCountries: allowedShippingCountries,
            localizedPricesMetas: localizedPricesMetas,
            exchangeRateMeta: exchangeRateMeta,
            adaptivePricingActive: adaptivePricingActive,
            automaticTaxEnabled: automaticTaxEnabled,
            automaticTaxAddressSource: automaticTaxAddressSource,
            elementsSession: elementsSession,
            allResponseFields: dict
        ) as? Self
    }
}

// MARK: - Parsing helpers

extension PaymentPagesAPIResponse {

    // MARK: Amounts

    /// Builds a ``Checkout/Amount`` from a minor-unit value plus the session currency.
    static func makeAmount(_ minorUnitsAmount: Int, currency: String?) -> Checkout.Amount {
        let formatted: String
        if let currency, !currency.isEmpty {
            formatted = String.localizedAmountDisplayString(for: minorUnitsAmount, currency: currency)
        } else {
            formatted = "\(minorUnitsAmount)"
        }
        return Checkout.Amount(amount: formatted, minorUnitsAmount: minorUnitsAmount)
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
        let currency = (price?["currency"] as? String) ?? defaultCurrency

        let unitAmount: Checkout.Amount? = (price?["unit_amount"] as? Int).map {
            makeAmount($0, currency: currency)
        }
        let unitAmountDecimal = parseDecimalAmount(
            price?["unit_amount_decimal"] as? String,
            currency: currency
        )
        let subtotal = makeOptionalAmount(dict["subtotal"], currency: currency)
        let discount = makeOptionalAmount(dict["discount"], currency: currency)
        let taxExclusive = makeOptionalAmount(dict["tax_exclusive"], currency: currency)
        let taxInclusive = makeOptionalAmount(dict["tax_inclusive"], currency: currency)
        let total = makeOptionalAmount(dict["total"], currency: currency)
        let lineDiscountAmounts = parseLineDiscountAmounts(
            from: dict["discount_amounts"] as? [[AnyHashable: Any]] ?? [],
            currency: currency
        )
        let lineTaxAmounts = parseLineTaxAmounts(
            from: dict["tax_amounts"] as? [[AnyHashable: Any]] ?? [],
            currency: currency
        )
        let adjustableQuantity = parseAdjustableQuantity(from: dict["adjustable_quantity"] as? [AnyHashable: Any])

        return Checkout.LineItem(
            id: id,
            name: name,
            description: dict["description"] as? String,
            images: dict["images"] as? [String] ?? [],
            quantity: quantity,
            unitAmount: unitAmount,
            unitAmountDecimal: unitAmountDecimal,
            subtotal: subtotal,
            discount: discount,
            taxExclusive: taxExclusive,
            taxInclusive: taxInclusive,
            total: total,
            discountAmounts: lineDiscountAmounts,
            taxAmounts: lineTaxAmounts,
            adjustableQuantity: adjustableQuantity
        )
    }

    private static func parseDecimalAmount(_ value: String?, currency: String?) -> Checkout.DecimalAmount? {
        guard let value, let decimal = Decimal(string: value) else { return nil }
        let intValue = NSDecimalNumber(decimal: decimal).intValue
        return Checkout.DecimalAmount(
            amount: makeAmount(intValue, currency: currency).amount,
            minorUnitsAmount: decimal
        )
    }

    private static func makeOptionalAmount(_ value: Any?, currency: String?) -> Checkout.Amount? {
        guard let amount = value as? Int else { return nil }
        return makeAmount(amount, currency: currency)
    }

    private static func parseAdjustableQuantity(from dict: [AnyHashable: Any]?) -> Checkout.AdjustableQuantity? {
        guard let dict,
              let minimum = dict["minimum"] as? Int,
              let maximum = dict["maximum"] as? Int else { return nil }
        return Checkout.AdjustableQuantity(minimum: minimum, maximum: maximum)
    }

    // MARK: Shipping Options / Selected Shipping

    static func parseShippingOptions(from dict: [AnyHashable: Any], defaultCurrency: String?) -> [Checkout.ShippingOption] {
        guard let options = dict["shipping_options"] as? [[AnyHashable: Any]] else {
            return []
        }
        return options.compactMap { parseShippingOption(from: $0, defaultCurrency: defaultCurrency) }
    }

    static func parseSelectedShippingAmount(from dict: [AnyHashable: Any]) -> Int {
        if let lineItemGroup = dict["line_item_group"] as? [AnyHashable: Any],
           let shippingRate = lineItemGroup["shipping_rate"] as? [AnyHashable: Any],
           let amount = shippingRate["amount"] as? Int {
            return amount
        }
        return 0
    }

    static func parseSelectedShipping(
        from dict: [AnyHashable: Any],
        shippingOptions: [Checkout.ShippingOption],
        currency: String?
    ) -> Checkout.SelectedShipping? {
        guard let lineItemGroup = dict["line_item_group"] as? [AnyHashable: Any],
              let shippingRate = lineItemGroup["shipping_rate"] as? [AnyHashable: Any],
              let id = shippingRate["id"] as? String else {
            return nil
        }
        let resolvedOption = shippingOptions.first(where: { $0.id == id })
            ?? parseShippingOption(from: ["shipping_rate": shippingRate], defaultCurrency: currency)
        guard let option = resolvedOption else { return nil }

        let taxAmounts = parseLineTaxAmounts(
            from: lineItemGroup["shipping_tax_amounts"] as? [[AnyHashable: Any]] ?? [],
            currency: currency
        )
        return Checkout.SelectedShipping(shippingOption: option, taxAmounts: taxAmounts)
    }

    private static func parseShippingOption(from dict: [AnyHashable: Any], defaultCurrency: String?) -> Checkout.ShippingOption? {
        if let shippingRate = dict["shipping_rate"] as? [AnyHashable: Any] {
            guard let id = shippingRate["id"] as? String,
                  let amountInt = shippingRate["amount"] as? Int else {
                return nil
            }
            let currency = (shippingRate["currency"] as? String) ?? defaultCurrency ?? "usd"
            let displayName = shippingRate["display_name"] as? String
            let deliveryEstimate = parseDeliveryEstimate(shippingRate["delivery_estimate"] as? [AnyHashable: Any])
            return Checkout.ShippingOption(
                id: id,
                displayName: displayName,
                amount: makeAmount(amountInt, currency: currency),
                currency: currency,
                deliveryEstimate: deliveryEstimate
            )
        }
        return nil
    }

    private static func parseDeliveryEstimate(_ dict: [AnyHashable: Any]?) -> Checkout.DeliveryEstimate? {
        guard let dict else { return nil }
        let minimum = parseDeliveryBound(dict["minimum"] as? [AnyHashable: Any])
        let maximum = parseDeliveryBound(dict["maximum"] as? [AnyHashable: Any])
        // If neither bound parsed, there's nothing useful to show — don't hand back an empty estimate.
        guard minimum != nil || maximum != nil else { return nil }
        return Checkout.DeliveryEstimate(minimum: minimum, maximum: maximum)
    }

    private static func parseDeliveryBound(_ dict: [AnyHashable: Any]?) -> Checkout.DeliveryEstimate.Bound? {
        guard let dict,
              let value = dict["value"] as? Int else { return nil }
        let unit: Checkout.DeliveryEstimate.Bound.Unit
        switch (dict["unit"] as? String)?.lowercased() {
        case "hour": unit = .hour
        case "day": unit = .day
        case "business_day": unit = .businessDay
        case "week": unit = .week
        case "month": unit = .month
        default: unit = .unknown
        }
        return Checkout.DeliveryEstimate.Bound(unit: unit, value: value)
    }

    // MARK: Discounts

    static func parseDiscountAmounts(from dict: [AnyHashable: Any], currency: String?) -> [Checkout.DiscountAmount] {
        let lineItemGroup = dict["line_item_group"] as? [AnyHashable: Any]
        let discountAmounts = lineItemGroup?["discount_amounts"] as? [[AnyHashable: Any]] ?? []
        return discountAmounts.compactMap { discount in
            parseDiscountAmount(from: discount, currency: currency)
        }
    }

    private static func parseDiscountAmount(
        from dict: [AnyHashable: Any],
        currency: String?
    ) -> Checkout.DiscountAmount? {
        let amountValue = dict["amount"] as? Int ?? 0
        guard amountValue > 0 else { return nil }
        let couponDict = dict["coupon"] as? [AnyHashable: Any]
        let promotionCodeDict = dict["promotion_code"] as? [AnyHashable: Any]
        let displayName = (dict["display_name"] as? String)
            ?? (couponDict?["name"] as? String)
            ?? (couponDict?["id"] as? String)
            ?? String.Localized.discount
        return Checkout.DiscountAmount(
            amount: makeAmount(amountValue, currency: currency),
            displayName: displayName,
            promotionCode: promotionCodeDict?["code"] as? String
        )
    }

    private static func parseLineDiscountAmounts(
        from array: [[AnyHashable: Any]],
        currency: String?
    ) -> [Checkout.DiscountAmount] {
        return array.compactMap { parseDiscountAmount(from: $0, currency: currency) }
    }

    // MARK: Tax Amounts

    private static func parseSessionTaxAmounts(
        from dict: [AnyHashable: Any],
        currency: String?
    ) -> [Checkout.TaxAmount] {
        guard let lineItemGroup = dict["line_item_group"] as? [AnyHashable: Any] else {
            return []
        }
        return parseLineTaxAmounts(
            from: lineItemGroup["tax_amounts"] as? [[AnyHashable: Any]] ?? [],
            currency: currency
        )
    }

    private static func parseLineTaxAmounts(
        from array: [[AnyHashable: Any]],
        currency: String?
    ) -> [Checkout.TaxAmount] {
        return array.compactMap { dict in
            guard let amountInt = dict["amount"] as? Int,
                  let inclusive = dict["inclusive"] as? Bool else { return nil }
            let displayName = (dict["display_name"] as? String)
                ?? ((dict["tax_rate"] as? [AnyHashable: Any])?["display_name"] as? String)
                ?? String.Localized.tax
            return Checkout.TaxAmount(
                amount: makeAmount(amountInt, currency: currency),
                inclusive: inclusive,
                displayName: displayName
            )
        }
    }

    // MARK: Currency Options

    static func makeCurrencyOptions(
        from metas: [STPCheckoutSessionLocalizedPriceMeta],
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta?
    ) -> [Checkout.CurrencyOption] {
        return metas.map { meta -> Checkout.CurrencyOption in
            // Conversion details are only attached to the converted (localized) currency option.
            let conversion: Checkout.CurrencyConversion? = exchangeRateMeta.flatMap { rate in
                guard meta.currency.lowercased() == rate.localizedCurrency.lowercased() else { return nil }
                return Checkout.CurrencyConversion(fxRate: rate.exchangeRate, sourceCurrency: rate.sellCurrency)
            }
            return Checkout.CurrencyOption(
                amount: makeAmount(meta.total, currency: meta.currency),
                currency: meta.currency,
                currencyConversion: conversion
            )
        }
    }

}

// MARK: - Status / TaxStatus parsing helpers

extension Checkout.StatusType {
    static func statusType(from string: String) -> Checkout.StatusType {
        switch string.lowercased() {
        case "open": return .open
        case "complete": return .complete
        case "expired": return .expired
        default: return .unknown
        }
    }
}

extension Checkout.PaymentStatus {
    static func paymentStatus(from string: String) -> Checkout.PaymentStatus {
        switch string.lowercased() {
        case "paid": return .paid
        case "unpaid": return .unpaid
        case "no_payment_required": return .noPaymentRequired
        default: return .unknown
        }
    }
}
