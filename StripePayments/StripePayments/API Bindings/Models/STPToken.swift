//
//  STPToken.swift
//  StripePayments
//
//  Created by Saikat Chakrabarti on 11/5/12.
//  Copyright © 2012 Stripe, Inc. All rights reserved.
//

import Foundation

/// Possible Token types
@objc
public enum STPTokenType: Int {
    /// Account token type
    case account = 0
    /// Bank account token type
    case bankAccount
    /// Card token type
    case card
    /// PII token type
    case PII
    /// CVC update token type
    case cvcUpdate
}

/// A token returned from submitting payment details to the Stripe API. You should not have to instantiate one of these directly.
public class STPToken: NSObject, STPAPIResponseDecodable, STPSourceProtocol {
    /// You cannot directly instantiate an `STPToken`. You should only use one that has been returned from an `STPAPIClient` callback.
    override init() {
    }

    /// The value of the token. You can store this value on your server and use it to make charges and customers.
    /// - seealso: https://stripe.com/docs/payments/charges-api
    @objc public private(set) var tokenId = ""
    /// Whether or not this token was created in livemode. Will be YES if you used your Live Publishable Key, and NO if you used your Test Publishable Key.
    @objc public private(set) var livemode = false
    /// The type of this token.
    @objc public private(set) var type: STPTokenType = .account
    /// The credit card details that were used to create the token. Will only be set if the token was created via a credit card or Apple Pay, otherwise it will be
    /// nil.
    @objc public private(set) var card: STPCard?
    /// The bank account details that were used to create the token. Will only be set if the token was created with a bank account, otherwise it will be nil.
    @objc public private(set) var bankAccount: STPBankAccount?
    /// When the token was created.
    @objc public private(set) var created: Date?
    @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        return tokenId
    }

    /// :nodoc:
    @objc public override var debugDescription: String {
        let token = tokenId
        let livemode = self.livemode ? "live mode" : "test mode"
        return "\(token) (\(livemode))"
    }

    // MARK: - Equality
    /// :nodoc:
    @objc
    public override func isEqual(_ object: Any?) -> Bool {
        return isEqual(to: object as? STPToken)
    }

    /// :nodoc:
    @objc public override var hash: Int {
        return tokenId.hash
    }

    func isEqual(to object: STPToken?) -> Bool {
        if self == object {
            return true
        }

        guard let object = object else {
            return false
        }

        if (card != nil || object.card != nil) && (!(card == object.card)) {
            return false
        }

        if (bankAccount != nil || object.bankAccount != nil)
            && (!(bankAccount == object.bankAccount))
        {
            return false
        }

        if let created1 = object.created {
            return livemode == object.livemode && type == object.type && (tokenId == object.tokenId)
                && created == created1 && (card == object.card)
        }
        return false
    }

    // MARK: - STPSourceProtocol
    @objc public var stripeID: String {
        return tokenId
    }

    // MARK: - STPAPIResponseDecodable
    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else { return nil }
        let dict = response.stp_dictionaryByRemovingNulls()
        guard let stripeId = dict.stp_string(forKey: "id"),
            let created = dict.stp_date(forKey: "created"),
            let rawType = dict.stp_string(forKey: "type"),
            dict["livemode"] != nil, self._isValidRawTokenType(rawType)
        else {
            return nil
        }

        let token = STPToken.init()
        token.tokenId = stripeId
        token.livemode = dict.stp_bool(forKey: "livemode", or: true)
        token.created = created
        token.type = self._tokenType(for: rawType)

        let rawCard = dict.stp_dictionary(forKey: "card")
        token.card = STPCard.decodedObject(fromAPIResponse: rawCard)

        let rawBankAccount = dict.stp_dictionary(forKey: "bank_account")
        token.bankAccount = STPBankAccount.decodedObject(fromAPIResponse: rawBankAccount)

        token.allResponseFields = dict

        return token as? Self
    }

    // MARK: - STPTokenType
    class func _isValidRawTokenType(_ rawType: String?) -> Bool {
        if (rawType == "account") || (rawType == "bank_account") || (rawType == "card")
            || (rawType == "pii") || (rawType == "cvc_update")
        {
            return true
        }
        return false
    }

    class func _tokenType(for rawType: String?) -> STPTokenType {
        if rawType == "account" {
            return .account
        } else if rawType == "bank_account" {
            return .bankAccount
        } else if rawType == "card" {
            return .card
        } else if rawType == "pii" {
            return .PII
        } else if rawType == "cvc_update" {
            return .cvcUpdate
        }

        // default return STPTokenTypeAccount (this matches other default enum behavior)
        return .account
    }
}
