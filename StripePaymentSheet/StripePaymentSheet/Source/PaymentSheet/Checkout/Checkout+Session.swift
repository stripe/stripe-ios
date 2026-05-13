//
//  Checkout+Session.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripePayments

// MARK: - Session

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A read-only representation of a Stripe Checkout Session.
    public final class Session {
        // MARK: - Public Properties

        /// The ID of the Checkout Session.
        public var id: String { stpSession.id }

        /// Billing details of the customer.
        public var billingAddress: Checkout.ContactAddress? {
            get { stpSession.billingAddress }
        }

        /// The business name as configured in the Business Public Details settings of
        /// your Stripe account.
        public var businessName: String? { stpSession.businessName }

        /// Three-letter ISO 4217 currency code in lowercase (e.g. `"usd"`).
        public var currency: String? { stpSession.currency }

        /// The currency options available on the Checkout Session when adaptive pricing is active.
        /// Empty when adaptive pricing is not active.
        public var currencyOptions: [Checkout.CurrencyOption] { stpSession.currencyOptions }

        /// The aggregate amounts calculated per discount for all line items.
        public var discountAmounts: [Checkout.DiscountAmount] { stpSession.discountAmounts }

        /// The customer's email address.
        public var email: String? { stpSession.email }

        /// The line items the customer is purchasing.
        public var lineItems: [Checkout.LineItem] { stpSession.lineItems }

        /// `true` if this object exists in live mode, `false` for test mode.
        public var livemode: Bool { stpSession.livemode }

        /// The factor used to convert between minor and major currency units. For USD this
        /// is `100`; for JPY this is `1`. `nil` when the session has no currency (e.g. setup mode).
        public var minorUnitsAmountDivisor: Int? { stpSession.minorUnitsAmountDivisor }

        /// Payment methods attached to the customer.
        public var savedPaymentMethods: [STPPaymentMethod] { stpSession.savedPaymentMethods }

        /// The selected shipping option, if any.
        public var shipping: Checkout.SelectedShipping? { stpSession.shipping }

        /// Shipping address of the customer.
        public var shippingAddress: Checkout.ContactAddress? {
            get { stpSession.shippingAddress }
        }

        /// The list of shipping options that can be selected.
        public var shippingOptions: [Checkout.ShippingOption] { stpSession.shippingOptions }

        /// Status of the Checkout Session.
        ///
        /// `nil` if the server did not return a status. When non-nil, ``Status.paymentStatus``
        /// is populated from the top-level payment status.
        public var status: Checkout.Status? { stpSession.status }

        /// Details about the tax computation status and aggregated tax amounts.
        public var tax: Checkout.Tax { stpSession.tax }

        /// Tax and discount details for the computed total amount.
        public var total: Checkout.Total? { stpSession.total }

        // MARK: - Internal

        /// The underlying API model. Used internally for properties not exposed on the public API.
        let stpSession: STPCheckoutSession

        init(_ stpSession: STPCheckoutSession) {
            self.stpSession = stpSession
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
