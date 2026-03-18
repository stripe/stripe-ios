//
//  Checkout+Session.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/26.
//

import Foundation

// MARK: - Session Protocol

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// A read-only snapshot of a Stripe Checkout Session.
    public protocol Session {
        /// Unique identifier for this checkout session.
        var id: String { get }

        /// The mode of this checkout session.
        var mode: Checkout.Mode { get }

        /// The status of this checkout session, or `nil` if not yet determined.
        var status: Checkout.Status? { get }

        /// The payment status of this checkout session.
        var paymentStatus: Checkout.PaymentStatus { get }

        /// Three-letter ISO 4217 currency code in lowercase (e.g. `"usd"`).
        var currency: String? { get }

        /// Whether this session was created in live mode.
        var livemode: Bool { get }

        /// A summary of monetary totals for this session, or `nil` if not yet available.
        var totals: Checkout.Totals? { get }

        /// The line items purchased by the customer.
        var lineItems: [Checkout.LineItem] { get }

        /// The shipping rate options available for this session.
        var shippingOptions: [Checkout.ShippingOption] { get }

        /// The currently selected shipping option, or `nil` if none is selected.
        var selectedShippingOption: Checkout.ShippingOption? { get }

        /// The discounts applied to this session.
        var discounts: [Checkout.Discount] { get }

        /// The promotion code currently applied to this session, or `nil`.
        var appliedPromotionCode: String? { get }

        /// The ID of the Stripe customer for this session, or `nil` if no customer is attached.
        var customerId: String? { get }

        /// The customer's email address, or `nil` if not available.
        var customerEmail: String? { get }

        /// The URL to the hosted Checkout page, or `nil` if not using hosted mode.
        var url: URL? { get }

        /// The billing address set via ``Checkout/updateBillingAddress(_:)``, or `nil`.
        var billingAddress: Checkout.AddressUpdate? { get }

        /// The shipping address set via ``Checkout/updateShippingAddress(_:)``, or `nil`.
        var shippingAddress: Checkout.AddressUpdate? { get }
    }
}

// MARK: - Mode

@_spi(CheckoutSessionsPreview)
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

// MARK: - Status

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// The status of a checkout session.
    public enum Status: Sendable {
        /// A status not recognized by this version of the SDK.
        case unknown
        /// The checkout session is still in progress. Payment processing has not started.
        case open
        /// The checkout session is complete. Payment processing may still be in progress.
        case complete
        /// The checkout session has expired. No further processing will occur.
        case expired
    }
}

// MARK: - PaymentStatus

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// The payment status of a checkout session.
    public enum PaymentStatus: Sendable {
        /// A payment status not recognized by this version of the SDK.
        case unknown
        /// The payment funds are available in your account.
        case paid
        /// The payment funds are not yet available in your account.
        case unpaid
        /// The payment is delayed to a future date, or the session is in setup mode
        /// and doesn't require a payment at this time.
        case noPaymentRequired
    }
}

// MARK: - Totals

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// Monetary totals for a checkout session.
    ///
    /// All amounts are in the smallest currency unit (e.g. cents for USD).
    public struct Totals: Sendable, Hashable {
        /// The subtotal amount before discounts and taxes.
        public let subtotal: Int
        /// The total amount after discounts and taxes.
        public let total: Int
        /// The amount due from the customer.
        public let due: Int
        /// The total discount amount applied.
        public let discount: Int
        /// The total shipping amount.
        public let shipping: Int
        /// The total tax amount applied.
        public let tax: Int
    }
}

// MARK: - LineItem

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// A line item in a checkout session.
    public struct LineItem: Sendable, Hashable, Identifiable {
        /// Unique identifier for this line item.
        public let id: String
        /// The display name for this line item.
        public let name: String
        /// The quantity of this line item.
        public let quantity: Int
        /// The per-unit price in the smallest currency unit.
        public let unitAmount: Int
        /// Three-letter ISO 4217 currency code in lowercase.
        public let currency: String
    }
}

// MARK: - ShippingOption

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// A shipping option available in a checkout session.
    public struct ShippingOption: Sendable, Hashable, Identifiable {
        /// The shipping rate ID.
        public let id: String
        /// The display name shown to the customer.
        public let displayName: String
        /// The shipping amount in the smallest currency unit.
        public let amount: Int
        /// Three-letter ISO 4217 currency code in lowercase.
        public let currency: String
    }
}

// MARK: - Discount

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// A discount applied to a checkout session.
    public struct Discount: Sendable, Hashable {
        /// The coupon applied to this discount.
        public let coupon: Checkout.Coupon
        /// The promotion code used, if this discount was applied via a promotion code.
        public let promotionCode: String?
        /// The discount amount in the smallest currency unit.
        public let amount: Int
    }
}

// MARK: - Coupon

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// A coupon associated with a discount.
    public struct Coupon: Sendable, Hashable, Identifiable {
        /// The coupon identifier.
        public let id: String
        /// The display name of the coupon.
        public let name: String?
        /// The percentage off, if this is a percentage-based coupon.
        public let percentOff: Double?
        /// The fixed amount off in the smallest currency unit, if this is a fixed-amount coupon.
        public let amountOff: Int?
    }
}
