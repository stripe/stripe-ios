//
//  PaymentMethod.swift
//  StripeApplePay
//
//  Created by David Estes on 6/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    /// PaymentMethod objects represent your customer's payment instruments. They can be used with PaymentIntents to collect payments.
    /// - seealso: https://stripe.com/docs/api/payment_methods
    public struct PaymentMethod: UnknownFieldsDecodable {
        /// The Stripe ID of the PaymentMethod.
        public let id: String

        /// Time at which the object was created. Measured in seconds since the Unix epoch.
        public var created: Date?
        /// `YES` if the object exists in live mode or the value `NO` if the object exists in test mode.
        public var livemode = false

        /// The type of the PaymentMethod.  The corresponding, similarly named property contains additional information specific to the PaymentMethod type.
        /// e.g. if the type is `Card`, the `card` property is also populated.
        public var type: PaymentMethodType?

        /// The type of the PaymentMethod.
        @frozen public enum PaymentMethodType: String, SafeEnumCodable {
            /// A card payment method.
            case card
            /// An unknown type.
            case unknown
            case unparsable
            // TODO: This is @frozen because of a bug in the Xcode 12.2 Swift compiler.
            // Remove @frozen after Xcode 12.2 support has been dropped.
        }

        /// Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
        public var billingDetails: BillingDetails?
        /// The ID of the Customer to which this PaymentMethod is saved. Nil when the PaymentMethod has not been saved to a Customer.
        public var customerId: String?
        /// If this is a card PaymentMethod (ie `self.type == .card`), this contains additional details.
        public var card: Card?

        /// :nodoc:
        public struct Card: UnknownFieldsDecodable {
            public var _allResponseFieldsStorage: NonEncodableParameters?
            /// The issuer of the card.
            public private(set) var brand: Brand = .unknown

            /// The various card brands to which a payment card can belong.
            @frozen public enum Brand: String, SafeEnumCodable {
                /// Visa
                case visa
                /// American Express
                case amex
                /// Mastercard
                case mastercard
                /// Discover
                case discover
                /// JCB
                case jcb
                /// Diners Club
                case diners
                /// UnionPay
                case unionpay
                /// An unknown card brand
                case unknown
                case unparsable
                // TODO: This is @frozen because of a bug in the Xcode 12.2 Swift compiler.
                // Remove @frozen after Xcode 12.2 support has been dropped.
            }

            /// Two-letter ISO code representing the country of the card.
            public private(set) var country: String?
            /// Two-digit number representing the card’s expiration month.
            public private(set) var expMonth: Int
            /// Four-digit number representing the card’s expiration year.
            public private(set) var expYear: Int
            /// Card funding type. Can be credit, debit, prepaid, or unknown.
            public private(set) var funding: String?
            /// The last four digits of the card.
            public private(set) var last4: String?
            /// Uniquely identifies this particular card number. You can use this attribute to check whether two customers who’ve signed up with you are using the same card number, for example.
            public private(set) var fingerprint: String?

            /// Contains information about card networks that can be used to process the payment.
            public private(set) var networks: Networks?

            /// Contains details on how this Card maybe be used for 3D Secure authentication.
            public private(set) var threeDSecureUsage: ThreeDSecureUsage?

            /// If this Card is part of a Card Wallet, this contains the details of the Card Wallet.
            public private(set) var wallet: Wallet?

            public struct Networks: UnknownFieldsDecodable {
                public var _allResponseFieldsStorage: NonEncodableParameters?

                /// All available networks for the card.
                public private(set) var available: [String]?
                /// The preferred network for the card if one exists.
                public private(set) var preferred: String?
            }

            /// Contains details on how a `Card` may be used for 3D Secure authentication.
            public struct ThreeDSecureUsage: UnknownFieldsDecodable {
                public var _allResponseFieldsStorage: NonEncodableParameters?

                /// `true` if 3D Secure is supported on this card.
                public private(set) var supported = false
            }

            public struct Wallet: UnknownFieldsDecodable {
                public var _allResponseFieldsStorage: NonEncodableParameters?
                /// The type of the Card Wallet. A matching property is populated if the type is `.masterpass` or `.visaCheckout` containing additional information specific to the Card Wallet type.
                public private(set) var type: WalletType = .unknown
                /// Contains additional Masterpass information, if the type of the Card Wallet is `STPPaymentMethodCardWalletTypeMasterpass`
                public private(set) var masterpass: Masterpass?
                /// Contains additional Visa Checkout information, if the type of the Card Wallet is `STPPaymentMethodCardWalletTypeVisaCheckout`
                public private(set) var visaCheckout: VisaCheckout?

                /// The type of Card Wallet.
                @frozen public enum WalletType: String, SafeEnumCodable {
                    /// Amex Express Checkout
                    case amexExpressCheckout = "amex_express_checkout"
                    /// Apple Pay
                    case applePay = "apple_pay"
                    /// Google Pay
                    case googlePay = "google_pay"
                    /// Masterpass
                    case masterpass = "masterpass"
                    /// Samsung Pay
                    case samsungPay = "samsung_pay"
                    /// Visa Checkout
                    case visaCheckout = "visa_checkout"
                    /// An unknown Card Wallet type.
                    case unknown = "unknown"
                    case unparsable
                    // TODO: This is @frozen because of a bug in the Xcode 12.2 Swift compiler.
                    // Remove @frozen after Xcode 12.2 support has been dropped.
                }

                public struct Masterpass: UnknownFieldsDecodable {
                    public var _allResponseFieldsStorage: NonEncodableParameters?

                    /// Owner’s verified email. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
                    public private(set) var email: String?
                    /// Owner’s verified email. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
                    public private(set) var name: String?
                    /// Owner’s verified billing address. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
                    public private(set) var billingAddress: BillingDetails.Address?
                    /// Owner’s verified shipping address. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
                    public private(set) var shippingAddress: BillingDetails.Address?
                }

                /// A Visa Checkout Card Wallet
                /// - seealso: https://stripe.com/docs/visa-checkout
                public struct VisaCheckout: UnknownFieldsDecodable {
                    /// Owner’s verified email. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
                    public private(set) var email: String?
                    /// Owner’s verified email. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
                    public private(set) var name: String?
                    /// Owner’s verified billing address. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
                    public private(set) var billingAddress: BillingDetails.Address?
                    /// Owner’s verified shipping address. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
                    public private(set) var shippingAddress: BillingDetails.Address?

                    public var _allResponseFieldsStorage: NonEncodableParameters?
                }
            }
        }

        public var _allResponseFieldsStorage: NonEncodableParameters?
    }
}
