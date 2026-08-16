//
//  Checkout+Session.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/9/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

// MARK: - Session

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A read-only representation of a Stripe Checkout Session.
    public struct Session {
        // MARK: - Public Properties

        /// The ID of the Checkout Session.
        public let id: String

        /// The business name as configured in the Business Public Details settings of
        /// your Stripe account.
        public let businessName: String?

        /// Three-letter ISO 4217 currency code in lowercase (e.g. `"usd"`).
        public let currency: String?

        /// The currency options available on the Checkout Session when adaptive pricing is active.
        /// Empty when adaptive pricing is not active.
        public let currencyOptions: [Checkout.CurrencyOption]

        /// The aggregate amounts calculated per discount for all line items.
        public let discountAmounts: [DiscountAmount]

        /// The customer's email address.
        public let email: String?

        /// The items included in the order summary.
        public let orderSummaryItems: [OrderSummaryItem]

        /// `true` if this object exists in live mode, `false` for test mode.
        public let livemode: Bool

        /// The factor used to convert between minor and major currency units. For USD this
        /// is `100`; for JPY this is `1`. `nil` when the session has no currency (e.g. setup mode).
        public let minorUnitsAmountDivisor: Int?

        /// The currently selected payment option.
        public let paymentOption: PaymentOptionDisplayData?

        /// Shipping address of the customer.
        public let shippingAddress: ShippingAddress?

        /// Status of the Checkout Session.
        public let status: Status

        /// The tax computation state, if available.
        public let tax: Tax?

        /// The aggregate amounts calculated per tax rate for all line items, or `nil` when
        /// tax has not yet been computed.
        ///
        /// For example, if this contains $5 of exclusive state tax, $2 of exclusive county
        /// tax, and $1 of inclusive VAT, ``totals`` contains $7 in `taxExclusive` and $1 in
        /// `taxInclusive`.
        public let taxAmounts: [TaxAmount]?

        /// Aggregate subtotal, tax, discount, and total amounts for the Checkout Session.
        public let totals: Checkout.Session.Totals

        // MARK: - Internal Properties

        let paymentStatus: Status.PaymentStatus
        let paymentMethodOptions: STPPaymentMethodOptions?
        let customer: PaymentPagesAPIResponse.Customer?
        let savedPaymentMethodsOfferSave: STPCheckoutSessionSavedPaymentMethodsOfferSave?
        let setupFutureUsage: String?
        let setupFutureUsageForPaymentMethodType: [String: String]
        let allowedShippingCountries: [String]?
        let localizedPricesMetas: [STPCheckoutSessionLocalizedPriceMeta]
        let exchangeRateMeta: STPCheckoutSessionExchangeRateMeta?
        let adaptivePricingActive: Bool
        let billingAddressCollection: BillingAddressCollection
        let automaticTaxEnabled: Bool
        let automaticTaxAddressSource: String?
        let elementsSession: STPElementsSession

        enum BillingAddressCollection: String {
            case automatic = "auto"
            case required
        }
    }
}

extension Checkout.Session {
    /// An item included in the order summary.
    @frozen
    public enum OrderSummaryItem: Sendable, Hashable {
        /// A group of one-time Prices.
        case oneTimePrice(OneTimePrice)

        /// A group of one-time Prices and their aggregated amounts.
        public struct OneTimePrice: Sendable, Hashable {
            /// A stable key that uniquely identifies this item within the Checkout Session.
            public let key: String

            /// A description of the one-time Price group.
            public let description: String?

            /// The one-time Prices included in this group.
            public let items: [Item]

            /// Amounts aggregated across all one-time Prices in this group.
            public let amountDetails: AmountDetails

            /// A one-time Price included in the group.
            public struct Item: Sendable, Hashable {
                /// A stable key that identifies this item.
                public let key: String

                /// The customer-facing name of the product.
                public let displayName: String

                /// URLs of images for the product.
                public let images: [String]

                /// The unit amount for the Price.
                public let unitAmount: Amount

                /// The unit amount with additional decimal precision, if available.
                public let unitAmountDecimal: Amount?

                /// The label that describes how units of the product are named.
                public let unitLabel: String?

                /// The quantity of the Price included in the Checkout Session.
                public let quantity: Int

                /// The allowed quantity range when the customer can adjust the quantity.
                public let adjustableQuantity: AdjustableQuantity?
            }

            /// Amounts aggregated across all one-time Prices in the group.
            public struct AmountDetails: Sendable, Hashable {
                /// The total amount for the group.
                public let total: Amount

                /// The subtotal amount for the group before discounts and exclusive tax.
                public let subtotal: Amount

                /// The tax amounts applied to the group, or `nil` when no tax was applied.
                public let taxAmounts: [TaxAmount]?

                /// The discount applied to the group.
                public let discount: Amount

                /// The tax amount included in the prices.
                public let taxInclusive: Amount

                /// The tax amount added to the prices.
                public let taxExclusive: Amount
            }
        }
    }

    /// A monetary amount with a localized display string and a value in minor units.
    public struct Amount: Sendable, Hashable {
        /// The localized, formatted representation of the amount.
        ///
        /// For example, an amount of `1000` in `usd` is formatted as `"$10.00"`.
        public let amount: String

        /// The numeric, unformatted representation of the amount in minor units.
        ///
        /// For example, `"$10.00"` is represented as `1000`.
        public let minorUnitsAmount: Double

        public init(amount: String, minorUnitsAmount: Double) {
            self.amount = amount
            self.minorUnitsAmount = minorUnitsAmount
        }
    }

    /// A tax amount included in an order summary item or aggregated across the session.
    public struct TaxAmount: Sendable, Hashable {
        /// The localized, formatted representation of the tax amount.
        public let amount: String

        /// The numeric, unformatted representation of the tax amount in minor units.
        public let minorUnitsAmount: Double

        /// Whether the tax amount is included in the price.
        public let inclusive: Bool

        /// The customer-facing name of the tax rate.
        public let displayName: String

        /// The tax rate percentage, or `nil` for a flat tax amount.
        public let percentage: Double?
    }

    /// The allowed range for a customer-adjustable quantity.
    public struct AdjustableQuantity: Sendable, Hashable {
        /// Whether the customer can adjust the quantity.
        public let enabled: Bool

        /// The maximum quantity the customer can select.
        public let maximum: Int

        /// The minimum quantity the customer can select.
        public let minimum: Int
    }

    /// Display data for the currently selected payment option.
    public struct PaymentOptionDisplayData: Equatable {
        /// An image representing a payment method, such as the Apple Pay logo or a card brand.
        public let image: UIImage
        /// A customer-facing label representing the payment option.
        public let label: String
        /// The billing details associated with the selected payment option.
        public let billingDetails: PaymentSheet.BillingDetails?
        /// A string representation of the selected payment method type.
        public let paymentMethodType: String
        /// Mandate text that must be displayed when the PaymentElement is configured not to display it.
        public let mandateText: NSAttributedString?
    }
}
