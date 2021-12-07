//
//  LinkedAccountResult.swift
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
}



public extension StripeAPI {

    struct LinkedAccount: StripeDecodable {
        enum Category: String, StripeEnumCodable, Equatable {
            case cash = "cash"
            case credit = "credit"
            case investment = "investment"
            case other = "other"
            case unparsable
        }
        enum Object: String, StripeEnumCodable, Equatable {
            case linkedAccount = "linked_account"
            case unparsable
        }
        enum Permissions: String, StripeEnumCodable, Equatable {
            case balances = "balances"
            case identity = "identity"
            case paymentMethod = "payment_method"
            case transactions = "transactions"
            case unparsable
        }
        enum Status: String, StripeEnumCodable, Equatable {
            case active = "active"
            case disconnected = "disconnected"
            case inactive = "inactive"
            case unparsable
        }
        enum Subcategory: String, StripeEnumCodable, Equatable {
            case checking = "checking"
            case creditCard = "credit_card"
            case lineOfCredit = "line_of_credit"
            case mortgage = "mortgage"
            case other = "other"
            case savings = "savings"
            case unparsable
        }
        enum SupportedPaymentMethodTypes: String, StripeEnumCodable, Equatable {
            case link = "link"
            case usBankAccount = "us_bank_account"
            case unparsable
        }
        enum CodingKeys: String, CodingKey {
            case category = "category"
            case created = "created"
            case displayName = "display_name"
            case id = "id"
            case institutionName = "institution_name"
            case last4 = "last4"
            case livemode = "livemode"
            case object = "object"
            case permissions = "permissions"
            case subcategory = "subcategory"
            case status = "status"
            case accountholder = "accountholder"
            case supportedPaymentMethodTypes = "supported_payment_method_types"
        }
        let accountholder: StripeAPI.AccountHolder
        /** The most recent information about the account&#x27;s balance. */
    //    var balance: ?
        /** The state of the most recent attempt to refresh the account balance. */
    //    var balanceRefresh: AnyOfbankConnectionsResourceLinkedAccountBalanceRefresh?
        let category: Category
        /** Time at which the object was created. Measured in seconds since the Unix epoch. */
        let created: Int
        /** A human-readable name that has been assigned to this account, either by the account holder or by the institution. */
        let displayName: String?
        /** Unique identifier for the object. */
        let id: String
        /** The name of the institution that holds this account. */
        let institutionName: String
        /** The last 4 digits of the account number. If present, this will be 4 numeric characters. */
        public let last4: String?
        /** Has the value &#x60;true&#x60; if the object exists in live mode or the value &#x60;false&#x60; if the object exists in test mode. */
        let livemode: Bool
        /** String representing the object&#x27;s type. Objects of the same type share the same value. */
        let object: Object
        /** The list of permissions granted by this account. */
        let permissions: [Permissions]?
        /** The status of the link to the account. */
        let status: Status
        /** If &#x60;category&#x60; is &#x60;cash&#x60;, one of:   - &#x60;checking&#x60;  - &#x60;savings&#x60;  - &#x60;other&#x60;  If &#x60;category&#x60; is &#x60;credit&#x60;, one of:   - &#x60;mortgage&#x60;  - &#x60;line_of_credit&#x60;  - &#x60;credit_card&#x60;  - &#x60;other&#x60;  If &#x60;category&#x60; is &#x60;investment&#x60; or &#x60;other&#x60;, this will be &#x60;other&#x60;. */
        let subcategory: Subcategory
        /** The [PaymentMethod type](https://stripe.com/docs/api/payment_methods/object#payment_method_object-type)(s) that can be created from this LinkedAccount. */
        let supportedPaymentMethodTypes: [SupportedPaymentMethodTypes]
        public var _allResponseFieldsStorage: NonEncodableParameters?
    }

}
