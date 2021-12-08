//
//  LinkedAccount.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/17/21.
//

import Foundation
@_spi(STP) import StripeCore

public extension StripeAPI {

    struct AccountHolder: StripeDecodable {

        // MARK: - Types

        enum ModelType: String, StripeEnumCodable, Equatable {
            case account = "account"
            case customer = "customer"
            case unparsable
        }

        // MARK: - StripeDecodable

        let account: String?
        let customer: String?
        let type: ModelType
        public var _allResponseFieldsStorage: NonEncodableParameters?

        // MARK: - Coding Keys

        enum CodingKeys: String, CodingKey {
            case account = "account"
            case customer = "customer"
            case type = "type"
        }
    }

    struct LinkedAccount: StripeDecodable {

        // MARK: - Types

        @frozen public enum Category: String, StripeEnumCodable, Equatable {
            case cash = "cash"
            case credit = "credit"
            case investment = "investment"
            case other = "other"
            case unparsable
        }
        @frozen public enum Permissions: String, StripeEnumCodable, Equatable {
            case balances = "balances"
            case identity = "identity"
            case paymentMethod = "payment_method"
            case transactions = "transactions"
            case unparsable
        }
        @frozen public enum Status: String, StripeEnumCodable, Equatable {
            case active = "active"
            case disconnected = "disconnected"
            case inactive = "inactive"
            case unparsable
        }
        @frozen public enum Subcategory: String, StripeEnumCodable, Equatable {
            case checking = "checking"
            case creditCard = "credit_card"
            case lineOfCredit = "line_of_credit"
            case mortgage = "mortgage"
            case other = "other"
            case savings = "savings"
            case unparsable
        }
        @frozen public enum SupportedPaymentMethodTypes: String, StripeEnumCodable, Equatable {
            case link = "link"
            case usBankAccount = "us_bank_account"
            case unparsable
        }

        // MARK: - CodingKey

        enum CodingKeys: String, CodingKey {
            case category = "category"
            case created = "created"
            case displayName = "display_name"
            case id = "id"
            case institutionName = "institution_name"
            case last4 = "last4"
            case livemode = "livemode"
            case permissions = "permissions"
            case subcategory = "subcategory"
            case status = "status"
            case accountholder = "accountholder"
            case supportedPaymentMethodTypes = "supported_payment_method_types"
        }

        // MARK: - Public Fields

        public let displayName: String?
        public let institutionName: String
        public let last4: String?
        public let accountholder: StripeAPI.AccountHolder
        public let category: Category
        public let created: Int
        public let id: String
        public let livemode: Bool
        public let permissions: [Permissions]?
        public let status: Status
        public let subcategory: Subcategory
        /** The [PaymentMethod type](https://stripe.com/docs/api/payment_methods/object#payment_method_object-type)(s) that can be created from this LinkedAccount. */
        public let supportedPaymentMethodTypes: [SupportedPaymentMethodTypes]
        public var _allResponseFieldsStorage: NonEncodableParameters?

    }

}
