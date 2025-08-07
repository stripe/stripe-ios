//
//  PaymentsListDefaultFiltersOptions.swift
//  StripeConnect
//
//  Created by Torrance Yang on 7/31/25.
//

import Foundation

// MARK: - String Extension for CamelCase to Snake Case Conversion
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

@_spi(DashboardOnly)
extension EmbeddedComponentManager {
    public struct PaymentsListDefaultFiltersOptions: Equatable, Codable {

        public enum AmountFilter: Equatable, Codable {
            case equals(Int)
            case greaterThan(Int)
            case lessThan(Int)
            case between(lowerBound: Int, upperBound: Int)

            private enum CodingKeys: String, CodingKey {
                case equals, greaterThan, lessThan, between
            }

            private struct BetweenAmount: Codable {
                let lowerBound: Int
                let upperBound: Int
            }
        }

        public enum DateFilter: Equatable, Codable {
            case before(Date)
            case after(Date)
            case between(start: Date, end: Date)

            private enum CodingKeys: String, CodingKey {
                case before, after, between
            }

            private struct BetweenDate: Codable {
                let start: Date
                let end: Date
            }
        }

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

        public var amount: AmountFilter?

        public var date: DateFilter?

        public var status: [Status]?

        public var paymentMethod: PaymentMethod?

        public init() {}
    }
}
