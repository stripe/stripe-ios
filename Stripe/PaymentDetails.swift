//
//  PaymentDetails.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 3/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore

typealias ConsumerSessionWithPaymentDetails = (session: ConsumerSession, paymentDetails: [ConsumerPaymentDetails])

/**
 PaymentDetails response for Link accounts
 
 For internal SDK use only
 */
@objc(STP_Internal_ConsumerPaymentDetails)
class ConsumerPaymentDetails: NSObject, STPAPIResponseDecodable {

    let stripeID: String
    let details: Details
    var isDefault: Bool

    // TODO(csabol) : Billing address
    
    let allResponseFields: [AnyHashable : Any]

    init(stripeID: String,
         details: Details,
         isDefault: Bool,
         allResponseFields: [AnyHashable: Any]) {
        self.stripeID = stripeID
        self.details = details
        self.isDefault = isDefault
        self.allResponseFields = allResponseFields
        super.init()
    }
    
    static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
        guard let dict = response?["redacted_payment_details"] as? [AnyHashable: Any] ?? response, // When this is from a list endpoint it isn't nested in redacted_payment_details
              let stripeID = dict["id"] as? String,
              let details = Details(dict),
              let isDefault = dict["is_default"] as? Bool else {
            return nil
        }
        
        return ConsumerPaymentDetails(stripeID: stripeID,
                                      details: details,
                                      isDefault: isDefault,
                                      allResponseFields: dict) as? Self
    }
    
    
    class ShareResponse: NSObject, STPAPIResponseDecodable {
        let paymentMethodID: String
        let allResponseFields: [AnyHashable : Any]
        
        init(paymentMethodID: String,
             allResponseFields: [AnyHashable: Any]) {
            self.paymentMethodID = paymentMethodID
            self.allResponseFields = allResponseFields
            super.init()
        }
        
        static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
            guard let dict = response,
                  let id = dict["payment_method"] as? String else {
                return nil
            }
            return ShareResponse(paymentMethodID: id,
                                 allResponseFields: dict) as? Self
        }
    }
    
}

// MARK: - Details
/// :nodoc:
extension ConsumerPaymentDetails {
    enum DetailsType: String, CaseIterable {
        case card
        case bankAccount = "bank_account"
    }
    
    enum Details {
       
        case card(card: Card)
        case bankAccount(bankAccount: BankAccount)
        
        init?(_ response: [AnyHashable: Any]) {
            guard let typeString = response["type"] as? String else {
                return nil
            }

            switch typeString.lowercased() {
            case "card":
                if let card = Card.decodedObject(fromAPIResponse: response) {
                    self = .card(card: card)
                } else {
                    return nil
                }
            case "bank_account":
                if let bankAccount = BankAccount.decodedObject(fromAPIResponse: response) {
                    self = .bankAccount(bankAccount: bankAccount)
                } else {
                    return nil
                }
            default:
                return nil
            }
        }
    }

    var type: DetailsType {
        switch details {
        case .card(_):
            return .card
        case .bankAccount(_):
            return .bankAccount
        }
    }
}

// MARK: - Card checks

extension ConsumerPaymentDetails.Details {
    /// For internal SDK use only
    @objc(STP_Internal_ConsumerPaymentDetails_CardChecks)
    class CardChecks: NSObject, STPAPIResponseDecodable {
        enum State: String {
            case pass = "PASS"
            case fail = "FAIL"
            case unchecked = "UNCHECKED"
            case unavailable = "UNAVAILABLE"
            case stateInvalid = "STATE_INVALID"
            // Catch all
            case unknown = "UNKNOWN"
        }

        let cvcCheck: State

        var allResponseFields: [AnyHashable: Any]

        init(cvcCheck: State, allResponseFields: [AnyHashable: Any]) {
            self.cvcCheck = cvcCheck
            self.allResponseFields = allResponseFields
            super.init()
        }

        static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
            guard
                let dict = response,
                let cvcCheck = dict["cvc_check"] as? String
            else {
                return nil
            }

            let cvcCheckState = State(rawValue: cvcCheck.uppercased()) ?? .unknown

            return CardChecks(
                cvcCheck: cvcCheckState,
                allResponseFields: dict) as? Self
        }
    }
}

// MARK: - Details.Card
extension ConsumerPaymentDetails.Details {
    class Card: NSObject, STPAPIResponseDecodable {
        
        let expiryYear: Int
        let expiryMonth: Int
        let brand: STPCardBrand
        let last4: String
        let checks: CardChecks?
        
        let allResponseFields: [AnyHashable : Any]
        
        /// A frontend convenience property, i.e. not part of the API Object
        var cvc: String? = nil
        
        required init(expiryYear: Int,
                      expiryMonth: Int,
                      brand: String,
                      last4: String,
                      checks: CardChecks?,
                      allResponseFields: [AnyHashable: Any]) {
            self.expiryYear = expiryYear
            self.expiryMonth = expiryMonth
            self.brand = STPPaymentMethodCard.brand(from: brand.lowercased())
            self.last4 = last4
            self.checks = checks
            self.allResponseFields = allResponseFields
            super.init()
        }
        
        static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
            guard let dict = response?["card_details"] as? [AnyHashable: Any],
                  let expiryYear = dict["exp_year"] as? Int,
                  let expiryMonth = dict["exp_month"] as? Int,
                  let brand = dict["brand"] as? String,
                  let last4 = dict["last4"] as? String else {
                return nil
            }

            let checks = CardChecks.decodedObject(fromAPIResponse: dict["checks"] as? [AnyHashable: Any])

            return Card(
                expiryYear: expiryYear,
                expiryMonth: expiryMonth,
                brand: brand,
                last4: last4,
                checks: checks,
                allResponseFields: dict
            ) as? Self
        }
    }
}

// MARK: - Details.Card - Helpers
extension ConsumerPaymentDetails.Details.Card {

    var shouldRecollectCardCVC: Bool {
        switch checks?.cvcCheck {
        case .fail, .unavailable, .unchecked:
            return true
        default:
            return false
        }
    }

    var hasExpired: Bool {
        let expiryDate = CardExpiryDate(month: expiryMonth, year: expiryYear)
        return expiryDate.expired()
    }

}

// MARK: - Details.BankAccount
extension ConsumerPaymentDetails.Details {
    class BankAccount: NSObject, STPAPIResponseDecodable {
        
        let iconCode: String?
        let name: String
        let last4: String
        
        let allResponseFields: [AnyHashable : Any]
        
        init(iconCode: String?,
             name: String,
             last4: String,
             allResponseFields: [AnyHashable: Any]) {
            self.iconCode = iconCode
            self.name = name
            self.last4 = last4
            self.allResponseFields = allResponseFields
            super.init()
        }

        static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
            guard let dict = response?["bank_account_details"] as? [AnyHashable: Any],
                  let name = dict["bank_name"] as? String,
                  let last4 = dict["last4"] as? String else {
                      return nil
                  }
            
            return BankAccount(iconCode: dict["bank_icon_code"] as? String,
                               name: name,
                               last4: last4,
                               allResponseFields: dict) as? Self
        }
    }
}

// MARK: - List Deserializer
/// :nodoc:
extension ConsumerPaymentDetails {
    /**
     Helper class to deserialize a list of ConsumerPaymentDetails from API responses
     */
    class ListDeserializer: NSObject, STPAPIResponseDecodable {
        let allResponseFields: [AnyHashable : Any]
        let paymentDetails: [ConsumerPaymentDetails]
        
        required init(paymentDetails: [ConsumerPaymentDetails],
                      allResponseFields: [AnyHashable: Any]) {
            self.paymentDetails = paymentDetails
            self.allResponseFields = allResponseFields
            super.init()
        }

        static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
            guard let response = response,
                  let data = response["redacted_payment_details"] as? [[AnyHashable: Any]] else {
                return nil
            }
            
            var paymentDetails = [ConsumerPaymentDetails]()
            for entry in data {
                if let paymentDetail = ConsumerPaymentDetails.decodedObject(fromAPIResponse: entry) {
                    paymentDetails.append(paymentDetail)
                }
            }
            
            return ListDeserializer(paymentDetails: paymentDetails, allResponseFields: response) as? Self
        }
    }
}

extension ConsumerPaymentDetails {
    var paymentSheetLabel: String {
        switch details {
        case .card(let card):
            return "••••\(card.last4)"
        case .bankAccount(let bank):
            return "••••\(bank.last4)"
        }
    }
    
    var prefillDetails: STPCardFormView.PrefillDetails? {
        switch details {
        case .card(let card):
            return STPCardFormView.PrefillDetails(last4: card.last4,
                                                  expiryMonth: card.expiryMonth,
                                                  expiryYear: card.expiryYear,
                                                  cardBrand: card.brand)
        case .bankAccount:
            return nil
        }
    }
    
    var cvc: String? {
        switch details {
        case .card(let card):
            return card.cvc
        case .bankAccount:
            return nil
        }
    }

    var accessibilityDescription: String {
        switch details {
        case .card(let card):
            // TODO(ramont): investigate why this returns optional
            let cardBrandName = STPCardBrandUtilities.stringFrom(card.brand) ?? ""
            let digits = card.last4.map({ String($0) }).joined(separator: ", ")
            return String(
                format: String.Localized.card_brand_ending_in_last_4,
                cardBrandName,
                digits
            )
        case .bankAccount(let bank):
            let digits = bank.last4.map({ String($0) }).joined(separator: ", ")
            return String(
                format: String.Localized.bank_account_ending_in_last_4,
                bank.name,
                digits
            )
        }
    }

}
