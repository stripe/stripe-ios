//
//  Checkout+SavedPaymentMethod.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/2026.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A payment method attached to the customer for this checkout session.
    public struct SavedPaymentMethod: Sendable, Hashable, Identifiable {
        /// ID of the PaymentMethod object.
        public let id: String
        /// The type of the payment method.
        public let type: PaymentMethodType
        /// Billing information associated with the payment method.
        public let billingDetails: BillingDetails
        /// Card details, if this is a card payment method.
        public let card: Card?

        public init(
            id: String,
            type: PaymentMethodType,
            billingDetails: BillingDetails,
            card: Card? = nil
        ) {
            self.id = id
            self.type = type
            self.billingDetails = billingDetails
            self.card = card
        }
    }

    /// The type of a saved payment method.
    public enum PaymentMethodType: Sendable, Hashable {
        case card
        case link
        case usBankAccount
        case sepaDebit
        case bacsDebit
        case auBecsDebit
        case payPal
        case cashApp
        case klarna
        case affirm
        case afterpayClearpay
        /// A type not recognized by this version of the SDK. The associated value is the
        /// raw API identifier (for example, `"crypto"`).
        case unknown(String)

        /// The raw API identifier for this payment method type (for example, `"us_bank_account"`).
        public var identifier: String {
            switch self {
            case .card: return "card"
            case .link: return "link"
            case .usBankAccount: return "us_bank_account"
            case .sepaDebit: return "sepa_debit"
            case .bacsDebit: return "bacs_debit"
            case .auBecsDebit: return "au_becs_debit"
            case .payPal: return "paypal"
            case .cashApp: return "cashapp"
            case .klarna: return "klarna"
            case .affirm: return "affirm"
            case .afterpayClearpay: return "afterpay_clearpay"
            case .unknown(let raw): return raw
            }
        }

        /// Creates a payment method type from its raw API identifier.
        public init(identifier: String) {
            switch identifier {
            case "card": self = .card
            case "link": self = .link
            case "us_bank_account": self = .usBankAccount
            case "sepa_debit": self = .sepaDebit
            case "bacs_debit": self = .bacsDebit
            case "au_becs_debit": self = .auBecsDebit
            case "paypal": self = .payPal
            case "cashapp": self = .cashApp
            case "klarna": self = .klarna
            case "affirm": self = .affirm
            case "afterpay_clearpay": self = .afterpayClearpay
            default: self = .unknown(identifier)
            }
        }
    }

    /// Billing information associated with a payment method.
    public struct BillingDetails: Sendable, Hashable {
        /// Email address.
        public let email: String?
        /// Billing phone number (including extension).
        public let phone: String?
        /// Full name.
        public let name: String?
        /// Address.
        public let address: Checkout.Address?

        public init(
            email: String? = nil,
            phone: String? = nil,
            name: String? = nil,
            address: Checkout.Address? = nil
        ) {
            self.email = email
            self.phone = phone
            self.name = name
            self.address = address
        }
    }

    /// Card details for a saved payment method.
    public struct Card: Sendable, Hashable {
        /// The card brand to use when displaying the card. May contain values like `"visa"`,
        /// `"mastercard"`, or any future brand.
        public let brand: String
        /// Two-digit number representing the card's expiration month.
        public let expMonth: Int
        /// Four-digit number representing the card's expiration year.
        public let expYear: Int
        /// The last four digits of the card.
        public let last4: String

        public init(brand: String, expMonth: Int, expYear: Int, last4: String) {
            self.brand = brand
            self.expMonth = expMonth
            self.expYear = expYear
            self.last4 = last4
        }
    }
}
