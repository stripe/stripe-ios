//
//  Checkout+Session.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

// MARK: - Session

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A read-only representation of a Stripe Checkout Session.
    public final class Session {
        // MARK: - Public Properties

        /// The ID of the Checkout Session.
        public let id: String

        /// Billing details of the customer.
        public let billingAddress: Checkout.ContactAddress?

        /// The business name as configured in the Business Public Details settings of
        /// your Stripe account.
        public let businessName: String?

        /// Three-letter ISO 4217 currency code in lowercase (e.g. `"usd"`).
        public let currency: String?

        /// The currency options available on the Checkout Session when adaptive pricing is active.
        /// Empty when adaptive pricing is not active.
        public let currencyOptions: [Checkout.CurrencyOption]

        /// The aggregate amounts calculated per discount for all line items.
        public let discountAmounts: [Checkout.DiscountAmount]

        /// The customer's email address.
        public let email: String?

        /// The line items the customer is purchasing.
        public let lineItems: [Checkout.LineItem]

        /// `true` if this object exists in live mode, `false` for test mode.
        public let livemode: Bool

        /// The factor used to convert between minor and major currency units. For USD this
        /// is `100`; for JPY this is `1`. `nil` when the session has no currency (e.g. setup mode).
        public let minorUnitsAmountDivisor: Int?

        /// Payment methods attached to the customer.
        public let savedPaymentMethods: [STPPaymentMethod]

        /// The selected shipping option, if any.
        public let shipping: Checkout.SelectedShipping?

        /// Shipping address of the customer.
        public let shippingAddress: Checkout.ContactAddress?

        /// The list of shipping options that can be selected.
        public let shippingOptions: [Checkout.ShippingOption]

        /// Status of the Checkout Session.
        ///
        /// `nil` if the server did not return a status. When non-nil, ``Status.paymentStatus``
        /// is populated from the top-level payment status.
        public let status: Checkout.Status?

        /// Details about the tax computation status and aggregated tax amounts.
        public let tax: Checkout.Tax

        /// Tax and discount details for the computed total amount.
        public let total: Checkout.Total?

        // MARK: - Internal Properties

        let mode: Checkout.Mode
        let paymentMethodOptions: STPPaymentMethodOptions?
        let customer: STPCheckoutSessionCustomer?
        let savedPaymentMethodsOfferSave: STPCheckoutSessionSavedPaymentMethodsOfferSave?
        let setupFutureUsage: String?
        let setupFutureUsageForPaymentMethodType: [String: String]
        let allowedShippingCountries: [String]?
        let localizedPricesMetas: [STPCheckoutSessionLocalizedPriceMeta]
        let exchangeRateMeta: STPCheckoutSessionExchangeRateMeta?
        let adaptivePricingActive: Bool
        let automaticTaxEnabled: Bool
        let automaticTaxAddressSource: String?
        let elementsSession: STPElementsSession?

        // MARK: - Init

        init(
            id: String,
            billingAddress: Checkout.ContactAddress?,
            businessName: String?,
            currency: String?,
            currencyOptions: [Checkout.CurrencyOption],
            discountAmounts: [Checkout.DiscountAmount],
            email: String?,
            lineItems: [Checkout.LineItem],
            livemode: Bool,
            minorUnitsAmountDivisor: Int?,
            savedPaymentMethods: [STPPaymentMethod],
            shipping: Checkout.SelectedShipping?,
            shippingAddress: Checkout.ContactAddress?,
            shippingOptions: [Checkout.ShippingOption],
            status: Checkout.Status?,
            tax: Checkout.Tax,
            total: Checkout.Total?,
            mode: Checkout.Mode,
            paymentMethodOptions: STPPaymentMethodOptions?,
            customer: STPCheckoutSessionCustomer?,
            savedPaymentMethodsOfferSave: STPCheckoutSessionSavedPaymentMethodsOfferSave?,
            setupFutureUsage: String?,
            setupFutureUsageForPaymentMethodType: [String: String],
            allowedShippingCountries: [String]?,
            localizedPricesMetas: [STPCheckoutSessionLocalizedPriceMeta],
            exchangeRateMeta: STPCheckoutSessionExchangeRateMeta?,
            adaptivePricingActive: Bool,
            automaticTaxEnabled: Bool,
            automaticTaxAddressSource: String?,
            elementsSession: STPElementsSession?
        ) {
            self.id = id
            self.billingAddress = billingAddress
            self.businessName = businessName
            self.currency = currency
            self.currencyOptions = currencyOptions
            self.discountAmounts = discountAmounts
            self.email = email
            self.lineItems = lineItems
            self.livemode = livemode
            self.minorUnitsAmountDivisor = minorUnitsAmountDivisor
            self.savedPaymentMethods = savedPaymentMethods
            self.shipping = shipping
            self.shippingAddress = shippingAddress
            self.shippingOptions = shippingOptions
            self.status = status
            self.tax = tax
            self.total = total
            self.mode = mode
            self.paymentMethodOptions = paymentMethodOptions
            self.customer = customer
            self.savedPaymentMethodsOfferSave = savedPaymentMethodsOfferSave
            self.setupFutureUsage = setupFutureUsage
            self.setupFutureUsageForPaymentMethodType = setupFutureUsageForPaymentMethodType
            self.allowedShippingCountries = allowedShippingCountries
            self.localizedPricesMetas = localizedPricesMetas
            self.exchangeRateMeta = exchangeRateMeta
            self.adaptivePricingActive = adaptivePricingActive
            self.automaticTaxEnabled = automaticTaxEnabled
            self.automaticTaxAddressSource = automaticTaxAddressSource
            self.elementsSession = elementsSession
        }
    }
}

// MARK: - Mode

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// The mode of a checkout session.
    public enum Mode: Sendable {
        /// A mode not recognized by this version of the SDK.
        case unknown
        /// Accept one-time payments for cards, iDEAL, and more.
        case payment
        /// Save payment details to charge your customers later.
        case setup
        /// Use Stripe Billing to set up fixed-price subscriptions.
        case subscription
    }
}
