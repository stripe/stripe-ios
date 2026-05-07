//
//  Checkout+Session.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/26.
//

import Foundation

// MARK: - Session Protocol

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A read-only representation of a Stripe Checkout Session.
    public protocol Session {
        /// The ID of the Checkout Session.
        var id: String { get }

        /// Billing details of the customer.
        var billingAddress: Checkout.ContactAddress? { get }

        /// The business name as configured in the Business Public Details settings of
        /// your Stripe account.
        var businessName: String? { get }

        /// Three-letter ISO 4217 currency code in lowercase (e.g. `"usd"`).
        var currency: String? { get }

        /// The currency options available on the Checkout Session when adaptive pricing is active.
        var currencyOptions: [Checkout.CurrencyOption]? { get }

        /// The aggregate amounts calculated per discount for all line items.
        var discountAmounts: [Checkout.DiscountAmount] { get }

        /// The customer's email address.
        var email: String? { get }

        /// The line items the customer is purchasing.
        var lineItems: [Checkout.LineItem] { get }

        /// `true` if this object exists in live mode, `false` for test mode.
        var livemode: Bool { get }

        /// The factor used to convert between minor and major currency units. For USD this
        /// is `100`; for JPY this is `1`. `nil` when the session has no currency (e.g. setup mode).
        var minorUnitsAmountDivisor: Int? { get }

        /// Payment methods attached to the customer.
        var savedPaymentMethods: [STPPaymentMethod] { get }

        /// The selected shipping option, if any.
        var shipping: Checkout.SelectedShipping? { get }

        /// Shipping address of the customer.
        var shippingAddress: Checkout.ContactAddress? { get }

        /// The list of shipping options that can be selected.
        var shippingOptions: [Checkout.ShippingOption] { get }

        /// Status of the Checkout Session.
        ///
        /// `nil` if the server did not return a status. When non-nil, ``Status.paymentStatus``
        /// is populated from the top-level payment status.
        var status: Checkout.Status? { get }

        /// Details about the tax computation status and aggregated tax amounts.
        var tax: Checkout.Tax { get }

        /// Tax and discount details for the computed total amount.
        var total: Checkout.Total? { get }
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
