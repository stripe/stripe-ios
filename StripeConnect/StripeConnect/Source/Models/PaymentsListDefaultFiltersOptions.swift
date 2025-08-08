//
//  PaymentsListDefaultFiltersOptions.swift
//  StripeConnect
//
//  Created by Torrance Yang on 7/31/25.
//

import Foundation

private extension String {
    /// Converts camelCase string to snake_case
    func camelCaseToSnakeCase() -> String {
        return self.unicodeScalars.reduce("") { result, scalar in
            if CharacterSet.uppercaseLetters.contains(scalar) {
                return result + "_" + String(scalar).lowercased()
            } else {
                return result + String(scalar)
            }
        }
    }
}

@available(iOS 15, *)
@_spi(DashboardOnly)
@_documentation(visibility: public)
extension EmbeddedComponentManager {
    @_documentation(visibility: public)
    public struct PaymentsListDefaultFiltersOptions: Equatable, Codable {

        @_documentation(visibility: public)
        public enum AmountFilter: Equatable, Codable {
            case equals(Double)
            case greaterThan(Double)
            case lessThan(Double)
            case between(lowerBound: Double, upperBound: Double)

            private enum CodingKeys: String, CodingKey {
                case equals, greaterThan, lessThan, between
            }

            private struct BetweenAmount: Codable {
                let lowerBound: Double
                let upperBound: Double
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case .equals(let value):
                    try container.encode(value, forKey: .equals)
                case .greaterThan(let value):
                    try container.encode(value, forKey: .greaterThan)
                case .lessThan(let value):
                    try container.encode(value, forKey: .lessThan)
                case .between(let lowerBound, let upperBound):
                    try container.encode(BetweenAmount(lowerBound: lowerBound, upperBound: upperBound), forKey: .between)
                }
            }
        }

        @_documentation(visibility: public)
        public enum DateFilter: Equatable, Codable {
            case before(Date)
            case after(Date)
            case between(start: Date, end: Date)

            private enum CodingKeys: String, CodingKey {
                case before, after, between
            }

            private struct BetweenDate: Codable {
                let start: TimeInterval
                let end: TimeInterval
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case .before(let date):
                    try container.encode(date.timeIntervalSince1970 * 1000, forKey: .before)
                case .after(let date):
                    try container.encode(date.timeIntervalSince1970 * 1000, forKey: .after)
                case .between(let start, let end):
                    try container.encode(BetweenDate(start: start.timeIntervalSince1970 * 1000, end: end.timeIntervalSince1970 * 1000), forKey: .between)
                }
            }
        }

        @_documentation(visibility: public)
        public enum Status: Codable, CaseIterable {
            case blocked
            case canceled
            case disputed
            case earlyFraudWarning
            case failed
            case incomplete
            case partiallyRefunded
            case pending
            case refundPending
            case refunded
            case successful
            case uncaptured

            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                let caseString = String(describing: self).camelCaseToSnakeCase()
                try container.encode(caseString)
            }
        }

        @_documentation(visibility: public)
        public enum PaymentMethod: Codable, CaseIterable {
            case achCreditTransfer
            case achDebit
            case acssDebit
            case affirm
            case afterpayClearpay
            case alipay
            case alma
            case amazonPay
            case amexExpressCheckout
            case androidPay
            case applePay
            case auBecsDebit
            case nzBankAccount
            case bancontact
            case bacsDebit
            case bitcoinSource
            case bitcoin
            case blik
            case boleto
            case boletoPilot
            case cardPresent
            case card
            case cashapp
            case crypto
            case customerBalance
            case demoPay
            case dummyPassthroughCard
            case gbpCreditTransfer
            case googlePay
            case eps
            case fpx
            case giropay
            case grabpay
            case ideal
            case idBankTransfer
            case idCreditTransfer
            case jpCreditTransfer
            case interacPresent
            case kakaoPay
            case klarna
            case konbini
            case krCard
            case krMarket
            case link
            case masterpass
            case mbWay
            case metaPay
            case multibanco
            case mobilepay
            case naverPay
            case netbanking
            case ngBank
            case ngBankTransfer
            case ngCard
            case ngMarket
            case ngUssd
            case vipps
            case oxxo
            case p24
            case payto
            case payByBank
            case paperCheck
            case payco
            case paynow
            case paypal
            case pix
            case promptpay
            case revolutPay
            case samsungPay
            case sepaCreditTransfer
            case sepaDebit
            case sofort
            case southKoreaMarket
            case swish
            case threeDSecure
            case threeDSecure2
            case threeDSecure2Eap
            case twint
            case upi
            case usBankAccount
            case visaCheckout
            case wechat
            case wechatPay
            case zip

            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                let caseString = String(describing: self).camelCaseToSnakeCase()
                try container.encode(caseString)
            }
        }

        @_documentation(visibility: public)
        public var amount: AmountFilter?

        @_documentation(visibility: public)
        public var date: DateFilter?

        @_documentation(visibility: public)
        public var status: [Status]?

        @_documentation(visibility: public)
        public var paymentMethod: PaymentMethod?

        @_documentation(visibility: public)
        public init() {}
    }
}
