//
//  Checkout+Session.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/26.
//

import Foundation
@_spi(STP) import StripePayments

// MARK: - Session

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A read-only representation of a Stripe Checkout Session.
    public final class Session {
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
            total: Checkout.Total?
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
